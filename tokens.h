#include <string>

// tokens for operations
enum op {ADD, SUB, MUL, DIV, MOD, EQ, GE, LE, NE, G, L};

int maptoopttoken(const std::string yytext) {
  if (yytext == "+") return ADD;
  if (yytext == "-") return SUB;
  if (yytext == "*") return MUL;
  if (yytext == "/" || yytext == "div") return DIV;
  if (yytext == "mod") return MOD;
  if (yytext == "=") return EQ;
  if (yytext == ">=") return GE;
  if (yytext == "<=") return LE;
  if (yytext == "!=") return NE;
  if (yytext == ">") return G;
  if (yytext == "<") return L;
  return -1;
}