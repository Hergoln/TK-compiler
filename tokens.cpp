#include "global.h"

int maptoopttoken(std::string yytext) {
  if (yytext == "+") return ADD;
  else if (yytext == "-") return SUB;
  else if (yytext == "or") return ORop;
  else if (yytext == "and") return AND;
  else if (yytext == "*") return MUL;
  else if (yytext == "/" || yytext == "div") return DIV;
  else if (yytext == "mod") return MOD;
  else if (yytext == "=") return EQ;
  else if (yytext == ">=") return GE;
  else if (yytext == "<=") return LE;
  else if (yytext == "!=") return NE;
  else if (yytext == ">") return G;
  else if (yytext == "<") return L;
  return -1;
}