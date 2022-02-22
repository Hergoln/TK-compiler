#include <stdlib.h>
#include <iostream>
#include <iomanip>
#include <string.h>
#include <vector>
#include "tokens.h"
#include "symbol.h"
#include "parser.hpp"

#define UNCONDITIONAL -1
#define ARRAY(start,end,type) {start,end,type}

extern int REFSIZE;
extern int NONESIZE;
extern int INTSIZE;
extern int REALSIZE;

extern int lineno;
extern int errRaised;
extern int verbose;
extern std::vector<Symbol> symtable;
extern Symbol EMPTY_SYMBOL;
extern ArrayInfo EMPTY_ARRAY;

// symbol
int insert (std::string, int, int);
int insert (std::string, int);
int insert (Symbol);
int lookup (std::string);
int lookup (std::string name, int token);

void initSymtable ();
void prntSymtable ();
void clearLocal ();
void setContext (bool);
int context ();
int getAddress (std::string);
int newTemp (int);
int newLabel ();
int newNum (std::string, int);
Symbol newArgument (int, ArrayInfo);
int getResultType (int, int); // indexes of symbols
int getStackSize ();

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
void emitIntToReal (Symbol, Symbol);
void emitRealToInt (Symbol, Symbol);
void emitAssign (Symbol, Symbol);
int emitCall (std::string);
int emitADDOP (Symbol, int, Symbol);
int emitMULOP (Symbol, int, Symbol);
int emitRELOP (Symbol, int, Symbol);
void emitJump (int, Symbol, Symbol, Symbol);
void emitWrite (Symbol);
void emitRead (Symbol);
void startFuncEmittion ();
void endFuncEmittion (std::string);
void emitPush (Symbol, Symbol);
void emitIncsp (int);
void dumpToFile (std::string);