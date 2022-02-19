#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <string.h>
#include <vector>
#include "tokens.h"
#include "symbol.h"
#include "parser.hpp"

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
void clearLocal ();
void setContext (bool);
int context ();
int getAddress (std::string);
int newTemp (int);
int getResultType (int, int); // indexes of symbols

// lexer
int yylex ();
int yylex_destroy ();

// parser
int yyparse ();
void yyerror (char const*);
const char* token_name (int);
bool checkType (int);

// tokens
int maptoopttoken (std::string);

// emit
void wrtInstr (std::string, std::string);
void wrtLbl (std::string);
void dumpToFile (std::string);
void emitAssign (Symbol, Symbol);
void emitCall (std::string);
void emitADDOP (Symbol, int, Symbol, Symbol);
void emitMULOP (Symbol, int, Symbol, Symbol);