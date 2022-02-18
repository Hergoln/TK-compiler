%{
#include "global.h"
#include "symbol.h"
#include <iostream>
#include <string>

int verbose = 0;
int errRaised = 0;
%}

%token-table

%token PROGRAM
%token VAR
%token ARRAY
%token OF

%token PROCEDURE
%token FUNCTION
%token BEG
%token END
%token NOT
%token OR
%token AND
%token IF
%token THEN
%token ELSE
%token DO
%token WHILE
%token WRITE
%token READ

%token ASSIGN
%token ADDOP
%token RELOP
%token MULOP

%token REAL
%token INT
%token VAL
%token ID

%token NONE
%token DONE

%%
program: 
    PROGRAM ID '(' program_arguments ')' ';' { toOS("Hello");}
    global_vars
    declarations
    program_continuation
    '.' program_end
    ;

program_arguments:
    ID |
    program_arguments ',' ID
    ;

global_vars:
    global_vars VAR global_symbols ':' type ';' |
    ;

simple_type:
    INT | REAL ;

type:
    simple_type | 
    ARRAY '[' VAL '.' '.' VAL']' OF simple_type;

global_symbols:
    ID |
    global_symbols ',' ID
    ;

declarations:
    declarations functional ';' |  ;

functional:
    function | procedure ;   
    
function:
    FUNCTION ID function_head ':' type ';'
    local_vars
    BEG function_body END;

function_head:
    '(' declarations_params ')' | ;

local_vars:
    local_vars VAR local_symbols ':' type ';' |
    ;

local_symbols:
    ID |
    local_symbols ',' ID
    ;

function_body:
    stmts | ;

stmts:
    stmts ';' stmt | stmt ;

declarations_params:
    paramGrps | ;

paramGrps:
    paramGrps ';' paramGrp | paramGrp ;

paramGrp:
    param ':' type;

param:
    param ',' ID | ID ; 

procedure:
    PROCEDURE ID procedure_head ';'
    local_vars
    BEG function_body END ;

procedure_head:
    '(' declarations_params ')' | ;

program_continuation:
    BEG program_body END;

program_body:
    stmts | ; 

stmt:
    var ASSIGN expression |
    factor | 
    write | 
    read |
    WHILE expression DO optional_stmts |
    IF expression THEN optional_stmts ELSE optional_stmts;

optional_stmts:
    BEG program_body END |
    stmt ;

expression:
    simpler_expression | simpler_expression RELOP simpler_expression;

simpler_expression:
    term | 
    ADDOP term | 
    simpler_expression log term |
    simpler_expression ADDOP term;

log:
    AND | OR;

term:
    factor | term MULOP factor;

factor:
    var |
    VAL |
    NOT factor |
    ID '(' expression_list ')' | 
    '(' expression ')';

var:
    ID | 
    ID '[' expression ']';

expression_list:
    expression ',' expression | expression;

read:
    READ '(' expression_list ')' {if(verbose)printf("read %d\n", $2);}

write:
    WRITE '(' expression_list ')' {if(verbose)printf("wrote %d\n", $2);}

program_end:
  DONE {
    return 0;
    };
%%


void yyerror(char const *s){
  printf("Error \"%s\" in line %d\n",s, lineno);
  errRaised++;
};

const char* token_name(int token) {
    return yytname[YYTRANSLATE(token)];
}

int main(int argc, char** argv){
  if (argc > 1){
    std::string flag = std::string(argv[1]);
    if (flag == "v" || flag == "verbose")
      verbose = 1;
  }
  yyparse();
  if(!errRaised) {
    printf("Compilation successful!!\n"); 
  }

  if(verbose) {   
    printf("Printout of symbols table:\n");
    prntSymtable();
  }
};