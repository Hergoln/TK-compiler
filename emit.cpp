#include "global.h"
#include <sstream>

std::stringstream outb;
std::string freezed;
std::string funcbody;

std::string printS(Symbol s) {
  return s.name + ", type=" + token_name(s.type) + ", token=" + token_name(s.token);
}

std::string sign(int a){
  return a < 0 ? "-" : "+";
}

std::string format (Symbol s) {
  std::string out = "";
  if(s.isReference && s.isGlobal == context() && s.type != ARRAY) {
    out += "*";
  }
  if(!s.isGlobal) {
    out += "BP" + sign(s.address);
  }
  if (s.isGlobal && s.type == ARRAY) {
    out += "#";
  }
  if(s.token == VAL || s.token == LABEL) {
    return "#" + s.name;
  } else if(s.isReference || s.token == VAR) {
    return out + std::to_string(abs(s.address));
  }
}

std::string formatName (std::string name) {
  return "$" + name;
}

void wrtInstr (std::string instr, std::string repr) {
  outb << "\t" << instr << "\t;" << repr << std::endl;
}

void wrtLbl (std::string label) {
  outb << label + ":" << std::endl;
}

struct Expanded {
  int tt;
  std::string st;
  Symbol l;
  Symbol r;
};

std::string tType (int t) {
  if (t == REAL) {
    return "r";
  }
  return "i";
}

void emitIntToReal (Symbol from, Symbol to) {
  wrtInstr(
    "inttoreal.i\t" + format(from) + "," + format(to),
    "inttoreal.i\t" + formatName(from.name) + "," + formatName(to.name));
}

void emitRealToInt (Symbol from, Symbol to) {
  wrtInstr(
    "realtoint.r\t" + format(from) + "," + format(to),
    "realtoint.r\t" + formatName(from.name) + "," + formatName(to.name));
}

// casts right side to match left side
Expanded expandAssign (Symbol lvar, Symbol rvar) {
  std::string stype;
  int ttype;
  if(lvar.type == rvar.type) {
    stype = tType(lvar.type);
    ttype = lvar.type;
    if (rvar.type == ARRAY) {
      lvar.arrInfo = rvar.arrInfo;
    }
  } else {
    if((lvar.type == INT || lvar.type == ARRAY) && rvar.type == REAL) {
      int temp = newTemp(INT);
      stype = tType(INT);
      ttype = INT;
      emitRealToInt(rvar, symtable[temp]);
      rvar = symtable[temp];
    } else if(lvar.type == REAL && (rvar.type == INT || lvar.type == ARRAY)) {
      int temp = newTemp(REAL);
      stype = tType(REAL); 
      ttype = REAL;
      emitIntToReal(rvar, symtable[temp]);
      rvar = symtable[temp];
    } else {
      yyerror(("Types " + 
      std::string(token_name(lvar.type)) + " and " + 
      std::string(token_name(rvar.type)) + " are incompatible.").c_str());
    }
  }
  return {ttype, stype, lvar, rvar};
}

void emitAssign (Symbol lvar, Symbol rvar) {
  // all different kinds of checks and casts
  Expanded exp = expandAssign(lvar, rvar);
  wrtInstr(
    "mov."+exp.st+"\t" + format(exp.r) + "," + format(exp.l), 
    "mov."+exp.st+"\t" + formatName(exp.r.name) + "," + formatName(exp.l.name));
}

int emitCall (std::string var) {
  wrtInstr("call.i\t#" + var, "call.i\t&" +var);
  return 0; // emit address of variable containing function result
}

int shouldChange(Symbol lvar, Symbol rvar) {
  int tL = REAL,tR = REAL;
  if (lvar.type == INT || lvar.type == ARRAY) tL = INT;
  if (rvar.type == INT || rvar.type == ARRAY) tR = INT;
  
  return tL == tR;
}

Expanded expand (Symbol lvar, Symbol rvar) {
  std::string stype;
  int ttype;
  if(shouldChange(lvar, rvar)) {
    if(lvar.type != rvar.type) {
      stype = tType(INT);
      ttype = INT;
    } else {
      stype = tType(lvar.type);
      ttype = lvar.type;
    }
  } else {
    if((lvar.type == INT || lvar.type == ARRAY) && rvar.type == REAL) {
      int temp = newTemp(REAL);
      stype = tType(REAL);
      ttype = REAL;
      emitIntToReal(lvar, symtable[temp]);
      lvar = symtable[temp];
    } else if(lvar.type == REAL && (rvar.type == INT || rvar.type == ARRAY)) {
      int temp = newTemp(REAL);
      stype = tType(REAL);
      ttype = REAL;
      emitIntToReal(rvar, symtable[temp]);
      rvar = symtable[temp];
    } else {
      std::cout << printS(lvar) << "; " << printS(rvar) << std::endl;
      yyerror(("Types " + 
      std::string(token_name(lvar.type)) + " and " + 
      std::string(token_name(rvar.type)) + " are incompatible.").c_str());
    }
  }
  return {ttype, stype, lvar, rvar};
}

std::string addop (int op) {
  switch (op)
  {
  case ADD: return "add.";
  case SUB: return "sub.";
  case ORop: return "or.";
  }
}

int emitADDOP (Symbol lvar, int op, Symbol rvar) {
  Expanded exp = expand(lvar, rvar);
  int result = newTemp(exp.tt);
  wrtInstr(
    addop(op) + exp.st + "\t" + format(exp.l) + 
    "," + format(exp.r) + "," + format(symtable[result]),
    addop(op) + exp.st + "\t" + formatName(exp.l.name) + 
    "," + formatName(exp.r.name) + "," + formatName(symtable[result].name)
  );

  return result;
}

std::string mulop (int op) {
  switch (op)
  {
  case MUL: return "mul.";
  case DIV: return "div.";
  case MOD: return "mod.";
  case AND: return "and.";
  }
}

int emitMULOP (Symbol lvar, int op, Symbol rvar) {
  Expanded exp = expand(lvar, rvar);
  int result = newTemp(exp.tt);
  wrtInstr(
    mulop(op) + exp.st + "\t" + format(exp.l) + 
    "," + format(exp.r) + "," + format(symtable[result]),
    mulop(op) + exp.st + "\t" + formatName(exp.l.name) + 
    "," + formatName(exp.r.name) + "," + formatName(symtable[result].name)
  );

  return result;
}

std::string relop(int op) {
  switch (op)
  {
  case EQ: return "e";
  case GE: return "ge";
  case LE: return "le";
  case NE: return "ne";
  case G: return "g";
  case L: return "l";
  }
}

void emitJump(int op, Symbol lvar, Symbol rvar, Symbol lbl) {
  if (op == UNCONDITIONAL) {
    wrtInstr("jump.i\t" + format(lbl) + "\t\t", "jump.i\t" + formatName(lbl.name));
  } else {
    /*look into array*/
    std::string type;
    type = (rvar.type == REAL || lvar.type == REAL ? "r" : "i");
    wrtInstr(
        "j" + relop(op) + "." + type + "\t" + format(lvar) + 
        "," + format(rvar) + "," + format(lbl),
        "j" + relop(op) + "." + type + "\t" + formatName(lvar.name) + 
        "," + formatName(rvar.name) + "," + formatName(lbl.name)
      );
  }
}

std::string formatRef (Symbol s) {
  std::string out = "";

  if(s.isReference) {
    out += "*";
  }

  if(!s.isGlobal) {
    out += "BP" + sign(s.address);
  }

  if(s.token == VAL || s.token == LABEL) {
    return "#" + s.name;
  } else if(s.isReference || s.token == VAR) {
    return out + std::to_string(abs(s.address));
  }
}

void emitWrite (Symbol sym) {
  wrtInstr(
    "write." + tType(sym.type) + "\t" + format(sym), 
    "write." + tType(sym.type) + "\t" + formatName(sym.name));
}

void emitRead (Symbol sym) {
  wrtInstr(
    "read." + tType(sym.type) + "\t" + formatRef(sym), 
    "read." + tType(sym.type) + "\t" + formatName(sym.name));
}

void startFuncEmittion() {  
  freezed = outb.str();
  outb.str(std::string());
}

void endFuncEmittion(std::string enterOffset) {
  wrtInstr("leave\t", "leave");
  wrtInstr("return\t", "return");
  
  funcbody = outb.str();
  outb.str(std::string());
  outb << freezed;
  wrtInstr("enter.i\t#" + enterOffset + "\t", "enter.i\t#" + enterOffset);
  outb << funcbody;
}

int eqTypes(Symbol one, Symbol other) {
  return one.type == other.type 
          && one.arrInfo.startVal == other.arrInfo.startVal
          && one.arrInfo.endVal == other.arrInfo.endVal;
}

void emitPush (Symbol arg, Symbol expected) {
  if(!eqTypes(expected, arg)) {
    Expanded exp = expandAssign(expected, arg);
    arg = exp.r;
  }
  if (arg.token == VAL) {
    int t = newTemp(expected.type);
    Symbol tSym = symtable[t];
    emitAssign(tSym, arg);
    arg = tSym;
  }
  std::string ref = "";
  if(!arg.isReference) {
    ref = "#";
  }
  wrtInstr(
    "push.i\t" + ref + formatRef(arg) + "\t\t", 
    "push.i\t&" + arg.name);
}

void emitIncsp(int incsp) {
  wrtInstr(
    "incsp.i\t#" + std::to_string(incsp),
    "incsp.i\t" + std::to_string(incsp)
  );
}

void dumpToFile (std::string fname) {
  std::cout << outb.str() << std::endl;
}