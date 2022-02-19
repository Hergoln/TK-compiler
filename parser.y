%{
#include "global.h"

int errRaised = 0;
std::vector<int> idsList;
%}

%token-table

%token PROGRAM
%token VAR
%token ARRAY
%token OF

%token PROC
%token FUNC
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
    PROGRAM ID 
    {
        symtable[$2].isGlobal = true;
        wrtInstr("jump.i\t#lbl0", "jump.i lab0");
    } 
    '(' program_arguments ')' ';'
    global_vars
    declarations
    {
        wrtLbl("lbl0");
    }
    program_continuation
    '.' DONE {
        wrtInstr("exit\t","exit");
        return 0;
    };
    ;

program_arguments: ID | program_arguments ',' ID;

global_vars:
    global_vars VAR global_symbols ':' type ';'
    {
        if(checkType($5)) YYERROR;

        for(auto &symTabIdx : idsList) {
            Symbol* sym = &symtable[symTabIdx];
            sym->type = $5;       
            sym->token = VAR;
            sym->isGlobal = true;
            //address
        }
        idsList.clear();
    }
    | //empty
    ;

simple_type:
    INT | REAL ;

type:
    simple_type | 
    ARRAY '[' VAL '.' '.' VAL']' OF simple_type
    {
        $$ = ARRAY;
        // info about array
    }
    ;

global_symbols:
    ID 
    {idsList.push_back($1);}
    | global_symbols ',' ID 
    {idsList.push_back($3);}
    ;

declarations:
    declarations functional ';' 
    | //empty
    ;

functional:
    heads local_vars BEG function_body END
    {
        wrtInstr("leave\t", "leave");
        wrtInstr("return\t", "return");
        if(verbose)  {
            prntSymtable();
            std::cout << std::endl;
        }
        clearLocal();
        // offset?
    }
    ;
    
heads:
    function | procedure;

function:
    FUNC ID 
    {
        wrtLbl(symtable[$2].name);
    }
    arguments ':' type ';'
    {
        // offset?
        symtable[$2].token = FUNC;
        symtable[$2].type = $5;
    }
    ;

arguments:
    '(' arguments_params ')'
    | //empty
    ;

arguments_params:
    paramGrps | ;

paramGrps:
    paramGrps ';' paramGrp | paramGrp ;

paramGrp:
    param ':' type 
    {
        if(checkType($3)) YYERROR;

        for(auto &symTabIdx : idsList) {
            Symbol* sym = &symtable[symTabIdx];
            sym->type = $3;
            sym->token = VAR;
            sym->isGlobal = false;
            sym->isReference = true;
        }
        idsList.clear();
    };

param:
    param ',' ID {idsList.push_back($3);}
    | ID {idsList.push_back($1);}; 

procedure:
    PROC ID
    {
        wrtLbl(symtable[$2].name);
    }
    arguments ';'
    {
        // offset?
        symtable[$2].token = PROC;
    }
    ;

local_vars:
    local_vars VAR local_symbols ':' type ';' |
    ;

local_symbols:
    ID 
    | local_symbols ',' ID
    ;

function_body:
    stmts | ;

stmts:
    stmts ';' stmt | stmt ;

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
%%


void yyerror(char const *s){
  printf("Error \"%s\" in line %d\n",s, lineno);
  errRaised++;
};

bool checkType(int type) {
    if(type != INT && type != REAL && type != ARRAY) {
        yyerror("Unknown type");
        return true;
    }
    return false;
}

const char* token_name(int token) {
    return yytname[YYTRANSLATE(token)];
}