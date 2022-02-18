#include "global.h"
#include <vector>
#include <memory>
#include <string>
#include <iostream>
#include <iomanip>
#include "symbol.h"

std::vector<Symbol> symtable;

int lookup (const std::string s) {
  for (int p = symtable.size() - 1; p > 0; p--)
    if (symtable[p].name == s)
      return p;
  return 0;
}

int insert (const std::string s, int tok) {
  symtable.push_back({s, tok, none});
  return symtable.size() - 1;
}

int insert (std::string s, int token, int type) {
  int look = lookup(s);
  if (look != 0) 
    return look;

  symtable.push_back({s, token, (vartype)type});
  return symtable.size() - 1;
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
    << "name:" << std::setw(lenName + 2) << symbol.name 
    << ", token:"<< std::setw(lenTok + 2) << token_name(symbol.token)
    << ", type:" << std::setw(LenType + 2) << token_name(symbol.type)
    << "\n";
  }
}