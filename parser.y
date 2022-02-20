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
%token IF
%token THEN
%token ELSE
%token DO
%token WHILE
%token WRITE
%token READ

%token ASSIGN
%token ADDOP
%token OR
%token RELOP
%token MULOP

%token REAL
%token INT
%token VAL
%token ID

%token NONE
%token LABEL
%token DONE

%%
program: 
    PROGRAM ID 
    {
        symtable[$2].isGlobal = true;
        symtable[$2].token = PROC;
        wrtInstr("jump.i\t#lbl0", "jump.i lbl0");
    } 
    '(' program_arguments ')' ';'
    global_vars
    declarations
    {
        wrtLbl("lbl0");
    }
    BEG function_body END
    '.' DONE {
        wrtInstr("exit\t","exit");
        return 0;
    };
    ;

program_arguments: ID | program_arguments ',' ID;

global_vars:
    global_vars VAR vars ':' type ';'
    {
        if(checkType($5)) YYERROR;

        for(auto &symTabIdx : idsList) {
            Symbol* sym = &symtable[symTabIdx];
            sym->type = $5;       
            sym->token = VAR;
            sym->isGlobal = true;
            sym->address = getAddress(sym->name);
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

vars:
    ID {idsList.push_back($1);}
    | vars ',' ID {idsList.push_back($3);}
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
        setContext(GLOBAL_CONTEXT);
        // offset?
    }
    ;
    
heads:
    function | procedure;

function:
    FUNC ID 
    {
        setContext(LOCAL_CONTEXT);
        wrtLbl(symtable[$2].name);
    }
    arguments ':' type ';'
    {
        // offset?
        Symbol* func = &symtable[$2];
        func->token = FUNC;
        func->type = $5;
        
        Symbol returnVar;
        returnVar.name = func->name;
        returnVar.token = VAR;
        returnVar.type = $5;
        returnVar.isReference = true;
        returnVar.isGlobal = false;
        insert(returnVar);
        // address?
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
    vars ':' type 
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
    local_vars VAR vars ':' type ';' 
    {
        if(checkType($5)) YYERROR;

        for(auto &symTabIdx : idsList) {
            Symbol* sym = &symtable[symTabIdx];
            sym->type = $5;       
            sym->token = VAR;
            //address
        }
        idsList.clear();
    }
    | // empty
    ;

function_body:
    stmts | ;

stmts:
    stmts ';' stmt | stmt ;

stmt:
    var ASSIGN simpler_expression
    {
        emitAssign(symtable[$1], symtable[$3]);
    }
    | factor 
    | write 
    | read 
    | WHILE
    {
        int loop = newLabel();
        int endLoop = newLabel();
        wrtLbl(symtable[loop].name);
        $$ = endLoop;
        $1 = loop;
    }
    expression DO 
    {
        int fNum = newNum("0", symtable[$2].type);
        emitJump(EQ, symtable[$3], symtable[fNum], symtable[$2]);
    }
    optional_stmts
    {
        emitJump(UNCONDITIONAL, EMPTY_SYMBOL, EMPTY_SYMBOL, symtable[$1]);
        wrtLbl(symtable[$2].name);
    }
    | IF expression 
    {
        int then = newLabel();
        int fNum = newNum("0", symtable[$2].type); // false
        emitJump(EQ, symtable[$2], symtable[fNum], symtable[then]);
        $2 = then;
    }
    THEN optional_stmts 
    {
        int elseL = newLabel();
        emitJump(UNCONDITIONAL, EMPTY_SYMBOL, EMPTY_SYMBOL, symtable[elseL]);
        wrtLbl(symtable[$2].name);
        $4 = elseL;
    }
    ELSE optional_stmts
    {
        wrtLbl(symtable[$4].name);
    }
    ;

optional_stmts:
    BEG function_body END 
    | stmt ;

expression:
    simpler_expression 
    | simpler_expression RELOP simpler_expression
    {
        int logicalVal = newTemp(getResultType($1, $3));
        int truthy = newLabel();
        emitJump($2, symtable[$1], symtable[$3], symtable[truthy]);

        int fNum = newNum("0", getResultType($1, $3)); // false
        int end = newLabel();        
        emitAssign(symtable[logicalVal], symtable[fNum]);
        emitJump(UNCONDITIONAL, EMPTY_SYMBOL, EMPTY_SYMBOL, symtable[end]);
        wrtLbl(symtable[truthy].name);

        int tNum = newNum("1", getResultType($1, $3)); // false
        emitAssign(symtable[logicalVal], symtable[tNum]);
        wrtLbl(symtable[end].name);
        $$ = logicalVal;
    }
    ;

simpler_expression:
    term 
    | ADDOP term
    {
        if ($1 == SUB) {
            int zero = newNum("0", symtable[$2].type);
            $$ = emitADDOP(symtable[zero], SUB, symtable[$2]);
        } else {
            $$ = $2;
        }
    }
    | simpler_expression OR term
    {
        $$ = emitADDOP(symtable[$1], ORop, symtable[$3]);
    }
    | simpler_expression ADDOP term
    {
        $$ = emitADDOP(symtable[$1], $2, symtable[$3]);
    }
    ;

term:
    factor 
    | term MULOP factor
    {
        $$ = emitMULOP(symtable[$1], $2, symtable[$3]);
    }
    ;

factor:
    var 
    | VAL 
    | NOT factor
    {
        if (symtable[$2].type == REAL){ // realtoint
            int temp = newTemp(INT);
            emitRealToInt(symtable[$2], symtable[temp]);
            $2 = temp;
        }

        int factorZero = newLabel();
        int fNum = newNum("0", INT); // false
        emitJump(EQ, symtable[$2], symtable[fNum], symtable[factorZero]);
        
        int endNegate = newLabel();
        int negated = newTemp(INT);
        emitAssign(symtable[negated], symtable[fNum]);
        emitJump(UNCONDITIONAL, EMPTY_SYMBOL, EMPTY_SYMBOL, symtable[endNegate]);
        wrtLbl(symtable[factorZero].name);

        int tNum = newNum("1", INT); // true
        emitAssign(symtable[negated], symtable[tNum]);
        wrtLbl(symtable[endNegate].name);

        $$ = negated;
    }
    | ID '(' expression_list ')'
    {
        Symbol sym = symtable[$1];
        if(sym.token == FUNC || sym.token == PROC) {
            emitCall(sym.name);
        }
    }
    | '(' expression ')'
    {
        $$ = $2;
    }
    ;

var:
    ID 
    {
        Symbol sym = symtable[$1];
        if(sym.token == FUNC || sym.token == PROC) {
            emitCall(sym.name);
        }
    }
    | ID '[' expression ']' {$$ = $1;};

expression_list:
    expression_list ',' expression 
    {
        idsList.push_back($3);
    }
    | expression
    {
        idsList.push_back($1);
    }
    ;                                                                                                          

read:
    READ '(' expression_list ')' {if(verbose)printf("read %d\n", $2);}

write:
    WRITE '(' expression_list ')' 
    {
        for (auto id : idsList) {
            emitWrite(symtable[id]);
        }
        idsList.clear();
    }
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