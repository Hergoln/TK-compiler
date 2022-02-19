#include "global.h"
#include "parser.hpp"

std::vector<Symbol> symtable;

void initSymtable() {
  Symbol read;
  read.name = "read";
  read.token = PROCEDURE;
  read.isGlobal = true;
  
  Symbol write;
  write.name = "write";
  write.token = PROCEDURE;
  write.isGlobal = true;

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


int insertPlain (Symbol sym) {
  symtable.push_back(sym);
  return symtable.size() - 1;
}

int insert (Symbol sym) {
  int look = lookup(sym.name);
  if (look >= 0) 
    return look;
  return insertPlain(sym);
}

int insert (const std::string s, int tok) {
  int look = lookup(s);
  if (look >= 0) 
    return look;
  Symbol sym;
  sym.name = s;
  sym.token = tok;
  return insertPlain(sym);
}

int insert (std::string s, int token, int type) {
  int look = lookup(s);
  if (look >= 0) 
    return look;
  Symbol sym;
  sym.name = s;
  sym.token = token;
  sym.type = type;
  return insertPlain(sym);
}

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
    << i++ << " "
    << (symbol.isGlobal ? "global " : "local  ")
    << std::setw(lenName + 2) << symbol.name << " "
    << std::setw(lenTok + 2) << token_name(symbol.token) << " "
    << std::setw(LenType + 2) << token_name(symbol.type)
    << "\n";
  }
}