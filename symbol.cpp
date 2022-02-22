#include "global.h"

Symbol EMPTY_SYMBOL;
ArrayInfo EMPTY_ARRAY;

std::vector<Symbol> symtable;
int globalContext = true;
int tempCount = 0;
int labelCount = 0;

// manipulation
void initSymtable() {
  Symbol read;
  read.name = "read";
  read.token = PROC;
  read.isGlobal = true;
  read.type = NONE;
  
  Symbol write;
  write.name = "write";
  write.token = PROC;
  write.isGlobal = true;
  write.type = NONE;

  Symbol lbl0;
  lbl0.name = "lbl0";
  lbl0.token = LABEL;
  lbl0.isGlobal = true;

  symtable.push_back(read);
  symtable.push_back(write);
}

int lookup (const std::string s) {
  for (int p = symtable.size() - 1; p > 0; p--)
    if (symtable[p].name == s)
      return p;
  return -1;
}

int lookup (std::string name, int token) {
  for (int p = symtable.size() - 1; p > 0; p--)
    if (symtable[p].name == name && symtable[p].token == token)
      return p;
  return -1;
}

int insertPlain (Symbol sym) {
  symtable.push_back(sym);
  return symtable.size() - 1;
}

int insert (Symbol sym) {
  int look = lookup(sym.name);
  if (look >= 0 && sym.isGlobal == symtable[look].isGlobal)
    return look;
  return insertPlain(sym);
}

int insert (const std::string s, int tok) {
  int look = lookup(s);
  if (look >= 0 && globalContext == symtable[look].isGlobal)
    return look;
  Symbol sym;
  sym.name = s;
  sym.token = tok;
  sym.isGlobal = globalContext;
  return insertPlain(sym);
}

int insert (std::string s, int token, int type) {
  int look = lookup(s);
  if (look >= 0 && globalContext == symtable[look].isGlobal) 
    return look;
  Symbol sym;
  sym.name = s;
  sym.token = token;
  sym.type = type;
  sym.isGlobal = globalContext;
  return insertPlain(sym);
}

int newTemp (int type) {
  Symbol t;
  t.isGlobal = globalContext;
  t.name = "t" + std::to_string(tempCount);
  t.type = type;
  t.token = VAR;
  t.address = 0;
  int index = insertPlain(t);
  symtable[index].address = getAddress(t.name); // has to be that way because t is already inserted
  ++tempCount;
  return index;
}

int newNum(std::string name, int type) {
  return insert (name, VAL, type);
}

// does not insert symbol into symtable
Symbol newArgument (int type, ArrayInfo info) {
  Symbol t;
  t.name = "argument";
  t.type = type;
  t.arrInfo = info;
  t.token = NONE;
  t.isReference = false;
  t.isGlobal = context();
  t.address = 2137;
  return t;
}

int newLabel() {
  return insert ("lbl" + std::to_string(++labelCount), LABEL, NONE);
}

void clearLocal() {
  for(int i=symtable.size()-1; i > 0 && !symtable[i].isGlobal; --i, symtable.pop_back());
}

void setContext(bool context) {
  globalContext = context;
}

// access
int context() {
  return globalContext;
}

int REFSIZE = 4;
int NONESIZE = 0;
int INTSIZE = 4;
int REALSIZE = 8;

int getSymbolSize(Symbol symbol) {
  if(symbol.isReference) {
    return REFSIZE;
  } else if(symbol.token == VAR) {
    if(symbol.type == INT) 
      return INTSIZE;
    else
      return REALSIZE;
  } else if(symbol.token == ARRAY) {
    // to change and calculate later
    return NONESIZE;
  }
  return NONESIZE;
}

/* look into*/
int getAddress(std::string name) {
  int address = 0;
  for (auto sym : symtable) {
    if(context() == LOCAL_CONTEXT){
      if(context() == sym.isGlobal && sym.address <= 0)
        address -= getSymbolSize(sym);
    } else {
      if(sym.name != name)
        address += getSymbolSize(sym);
    }
  }
  return address;
}

int getResultType(int l, int r) {
  return (symtable[l].type == REAL || symtable[r].type == REAL) ? REAL : INT;
}

/*
  Returns address of last allocated var in function/procedure
*/
int getStackSize() {
  int lastSym = -1;
  for (int i=0; i < symtable.size(); ++i) {
    Symbol sym = symtable[i];
    if(!sym.isGlobal && sym.token == VAR ) {
      lastSym = i;
    }
  }
  return symtable[lastSym].address > 0 ? 0 : abs(symtable[lastSym].address);
}

// representation
void prntSymtable() {
  int lenName = 0, lenTok = 0, LenType = 0;
  for (auto symbol : symtable) {
    if (lenName < symbol.name.length()) lenName = symbol.name.length();
    std::string tok = std::string(token_name(symbol.token));
    if (lenTok < tok.length()) lenTok = tok.length();
    std::string type = std::string(token_name(symbol.type));
    if (lenTok < type.length()) lenTok = type.length();
  }

  int i=0;
  for (auto symbol : symtable) {
    std::cout
    << std::setw(std::to_string(symtable.size()).length()) << i++ << " "
    << (symbol.isGlobal ? "global " : "local  ")
    << std::setw(4) << (symbol.isReference ? "ref" : "")
    << std::setw(lenTok + 2) << token_name(symbol.token) << " "
    << std::setw(lenName + 2) << symbol.name << " "
    << std::setw(LenType + 2) << token_name(symbol.type)
    << ((symbol.token == VAR || symbol.token == ARRAY) ? "\toffset=" + std::to_string(symbol.address) : "")
    << std::endl;
  }
}