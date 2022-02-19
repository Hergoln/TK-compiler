#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <string.h>
#include <vector>
#include "symbol.h"

#define LABEL 512

extern int lineno;
extern int errRaised;
extern int verbose;
extern std::vector<Symbol> symtable;

// symbol
int insert (std::string, int, int);
int insert (std::string, int);
int insert (Symbol);
int lookup (std::string);

void initSymtable ();
void prntSymtable ();
void clearLocal();

// lexer
int yylex ();
int yylex_destroy ();

// parser
int yyparse ();
void yyerror (char const*);
const char* token_name (int);
bool checkType (int);

// tokens
int maptoopttoken (const std::string);

// emit
void wrtInstr (std::string, std::string);
void wrtLbl (std::string);
void dumpToFile (std::string);