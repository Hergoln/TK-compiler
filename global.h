#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <string.h>
#include <vector>
#include "symbol.h"

extern int lineno;
extern int errRaised;
extern int verbose;
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
int maptoopttoken(const std::string);

// emit
void wrtInstr(std::string, std::string);
void wrtLbl(std::string);
void dumpToFile(std::string);