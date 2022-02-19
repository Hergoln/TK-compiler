#include "global.h"
#include <sstream>

std::stringstream outb;

std::string format(Symbol s) {
  if(s.token == VAL) {
    return "#" + s.name;
  } else if(s.isReference) {
    return "reference";
  } else if(s.token == VAR) {
    return std::to_string(s.address);
  }
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

std::string tType(int t) {
  if (t == REAL) {
    return "r";
  }
  return "i";
}

void emitIntToReal(Symbol from, Symbol to) {
  wrtInstr(
    "inttoreal.i\t" + format(from) + "," + format(to),
    "inttoreal.i\t" + from.name + "," + to.name);
}

void emitRealToInt(Symbol from, Symbol to) {
  wrtInstr(
    "realtoint.r\t" + format(from) + "," + format(to),
    "realtoint.r\t" + from.name + "," + to.name);
}

// casts right side to match left side
Expanded expandAssign(Symbol lvar, Symbol rvar) {
  std::string stype;
  int ttype;
  if(lvar.type == rvar.type) {
    stype = tType(lvar.type);
    ttype = lvar.type;
  } else {
    if(lvar.type == INT && rvar.type == REAL) {
      int temp = newTemp(REAL);
      stype = tType(REAL);
      ttype = REAL;
      emitIntToReal(rvar, symtable[temp]);
      rvar = symtable[temp];
    } else if(lvar.type == REAL && rvar.type == INT) {
      int temp = newTemp(INT);
      stype = tType(INT);
      ttype = INT;
      emitRealToInt(rvar, symtable[temp]);
      rvar = symtable[temp];
    } else {
      yyerror(("Types " + 
      std::string(token_name(lvar.type)) + " and " + 
      std::string(token_name(rvar.type)) + " are incompatible.").c_str());
    }
  }
  return {ttype, stype, lvar, rvar};
}

void emitAssign(Symbol lvar, Symbol rvar) {
  // all different kinds of checks and casts
  Expanded exp = expandAssign(lvar, rvar);
  wrtInstr(
    "mov."+exp.st+"\t" + format(exp.r) + "," + format(exp.l), 
    "mov."+exp.st+"\t" + exp.r.name + "," + exp.l.name);
}

void emitCall(std::string var) {
  wrtInstr("call.i\t#" + var, "call.i\t&" +var);
}

Expanded expand(Symbol lvar, Symbol rvar) {
  std::string stype;
  int ttype;
  if(lvar.type == rvar.type) {
    stype = tType(lvar.type);
    ttype = lvar.type;
  } else {
    if(lvar.type == INT && rvar.type == REAL) {
      int temp = newTemp(REAL);
      stype = tType(REAL);
      ttype = REAL;
      emitIntToReal(lvar, symtable[temp]);
      lvar = symtable[temp];
    } else if(lvar.type == REAL && rvar.type == INT) {
      int temp = newTemp(REAL);
      stype = tType(REAL);
      ttype = REAL;
      emitRealToInt(rvar, symtable[temp]);
      rvar = symtable[temp];
    } else {
      yyerror(("Types " + 
      std::string(token_name(lvar.type)) + " and " + 
      std::string(token_name(rvar.type)) + " are incompatible.").c_str());
    }
  }
  return {ttype, stype, lvar, rvar};
}

std::string addop(int op) {
  if (op == ADD) return "add.";
  else if (op == SUB) return "sub.";
}

void emitADDOP(Symbol lvar, int op, Symbol rvar, Symbol res) {
  Expanded exp = expand(lvar, rvar);

  wrtInstr(
    addop(op) + exp.st + "\t" + format(exp.l) + 
    "," + format(exp.r) + "," + format(res),
    addop(op) + exp.st + "\t$" + exp.l.name + 
    ",$" + exp.r.name + ",$" + res.name
  );
}

std::string mulop(int op) {
  switch (op)
  {
  case MUL: return "mul.";
  case DIV: return "div.";
  case MOD: return "mod.";
  }
}

void emitMULOP(Symbol lvar, int op, Symbol rvar, Symbol res) {
  Expanded exp = expand(lvar, rvar);

  wrtInstr(
    mulop(op) + exp.st + "\t" + format(exp.l) + 
    "," + format(exp.r) + "," + format(res),
    mulop(op) + exp.st + "\t$" + exp.l.name + 
    ",$" + exp.r.name + ",$" + res.name
  );
}

void dumpToFile(std::string fname) {
  std::cout << outb.str() << std::endl;
}