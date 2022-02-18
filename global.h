#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <vector>
#include "symbol.h"

extern int lineno;
extern std::vector<Symbol> symtable;

// symbol
int insert (std::string, int, int);
int insert (std::string, int);
int lookup (std::string);
void prntSymtable ();

// lexer
int yylex ();
int yylex_destroy ();

// parser
int yyparse ();
void yyerror (char const*);
const char* token_name(int);

// tokens
int matoptoken(const std::string);

// emit
void toOS(std::string);