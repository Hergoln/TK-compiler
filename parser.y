%{
#include "global.h"

int errRaised = 0;
std::vector<int> idsList;
std::vector<int> paramGrpIds;
std::vector<int> argumentsList;

int functionalOffset = 8; // FUNC = 12; PROC = 8;
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
    heads
    {
        startFuncEmittion();
        setContext(LOCAL_CONTEXT);
    }
    local_vars BEG function_body END
    {
        int stackSize = newNum(std::to_string(getStackSize()), INT);
        endFuncEmittion(symtable[stackSize].name);
        if(verbose)  {
            prntSymtable();
            std::cout << std::endl;
        }
        clearLocal();
        setContext(GLOBAL_CONTEXT);
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
        Symbol* func = &symtable[$2];
        func->token = FUNC;
        func->type = $6;
        
        std::vector<Symbol> args;
        for(auto id : paramGrpIds) {
            Symbol idS = symtable[id];
            args.push_back(newArgument(idS.type, idS.arrInfo));
        }
        func->arguments = args;
        paramGrpIds.clear();

        functionalOffset = 8;
        Symbol returnVar;
        returnVar.name = func->name;
        returnVar.token = VAR;
        returnVar.type = $6;
        returnVar.isReference = true;
        returnVar.isGlobal = false;
        returnVar.address = functionalOffset;
        insert(returnVar);
    }
    ;

arguments:
    '(' arguments_params ')'
    {
        std::vector<int>::iterator arg;
        for (arg = paramGrpIds.end() - 1; arg >= paramGrpIds.begin(); arg--) {
            functionalOffset += REFSIZE;
            symtable[*arg].address = functionalOffset;
        }
    }
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
            std::cout << sym->name << " " << token_name($3) << std::endl;
            sym->type = $3;
            sym->token = VAR;
            sym->isGlobal = false;
            sym->isReference = true;
        }
        paramGrpIds.insert(paramGrpIds.end(), idsList.begin(), idsList.end());
        idsList.clear();
    };

procedure:
    PROC ID
    {
        wrtLbl(symtable[$2].name);
        functionalOffset = 8;
    }
    arguments ';'
    {
        Symbol* proc = &symtable[$2];
        proc->token = PROC;
                
        std::vector<Symbol> args;
        for(auto id : idsList) {
            Symbol idS = symtable[id];
            args.push_back(newArgument(idS.type, idS.arrInfo));
        }
        proc->arguments = args;
        idsList.clear();
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
            sym->isGlobal = LOCAL_CONTEXT;
            sym->address = -1;
            sym->address = getAddress(sym->name);
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
    | BEG function_body END
    | proc
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
        stmt
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
        THEN stmt
        {
            int elseL = newLabel();
            emitJump(UNCONDITIONAL, EMPTY_SYMBOL, EMPTY_SYMBOL, symtable[elseL]);
            wrtLbl(symtable[$2].name);
            $4 = elseL;
        }
        ELSE stmt
        {
            wrtLbl(symtable[$4].name);
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

expression:
    simpler_expression 
    | simpler_expression RELOP simpler_expression
    {
        int logicalVal = newTemp(INT);
        int truthy = newLabel();
        emitJump($2, symtable[$1], symtable[$3], symtable[truthy]);

        int fNum = newNum("0", INT); // false
        int end = newLabel();        
        emitAssign(symtable[logicalVal], symtable[fNum]);
        emitJump(UNCONDITIONAL, EMPTY_SYMBOL, EMPTY_SYMBOL, symtable[end]);
        wrtLbl(symtable[truthy].name);

        int tNum = newNum("1", INT); // false
        emitAssign(symtable[logicalVal], symtable[tNum]);
        wrtLbl(symtable[end].name);
        $$ = logicalVal;
    }
    ;

term:
    factor 
    | term MULOP factor
    {
        $$ = emitMULOP(symtable[$1], $2, symtable[$3]);
    }
    ;

proc:
    ID 
    {
        // FUNC or PROC
    }
    | ID '(' expression_list ')'
    {
        // FUNC or PROC
    }
    | write 
    | read 
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
            int id = lookup(symtable[$1].name, FUNC);
            
            if(id == -1) {
                yyerror((symtable[$1].name + " is not callable or not assignable.").c_str());
                YYERROR;
            }

            Symbol func = symtable[id];
            if(func.arguments.size() < idsList.size()) {
                yyerror((symtable[$1].name + " called with too many arguments").c_str());
                YYERROR;
            } else if (func.arguments.size() > idsList.size()) {
                yyerror((symtable[$1].name + " called with too few arguments").c_str());
                YYERROR;
            }

            int incsp = 0;
            for(int id = 0; id < idsList.size(); ++id, incsp += REFSIZE) {
                Symbol given = symtable[idsList[id]];
                Symbol expectedType = func.arguments[id];
                emitPush(given, expectedType);
                
            }
            idsList.clear();
            
            // push result var
            int result = newTemp(func.type);
            emitPush(symtable[result], newArgument(func.type, func.arrInfo));
            incsp += REFSIZE;
            $$ = result;

            emitCall(func.name);
            
            newNum(std::to_string(incsp), INT);
            emitIncsp(incsp);
        }
    | '(' expression ')'
        {
            $$ = $2;
        }
    ;

var:
    ID 
    {
        if (symtable[$1].token != VAR) {
            Symbol func = symtable[$1];
            int incsp = 0;
            // push result var
            int result = newTemp(func.type);
            emitPush(symtable[result], newArgument(func.type, func.arrInfo));
            incsp += REFSIZE;
            $$ = result;

            emitCall(func.name);
            
            newNum(std::to_string(incsp), INT);
            emitIncsp(incsp);
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
    READ '(' expression_list ')' 
    {
        for (auto id : idsList) {
            emitRead(symtable[id]);
        }
        idsList.clear();
    }

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