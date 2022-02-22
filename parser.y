%{
#include "global.h"

int errRaised = 0;
std::vector<int> idsList;
std::vector<int> paramGrpIds;

ArrayInfo curArrayInfo;

int functionalOffset = 8; // FUNC = 12; PROC = 8;

std::string faultyArgsCount(std::string what, int is, int exp, std::string rel) {
    return what + " called with too " + rel + " arguments. Should be " + std::to_string(exp) + " but got " + std::to_string(is);
}

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
            sym->arrInfo = curArrayInfo;
        }
        idsList.clear();
    }
    | //empty
    ;

simple_type:
    INT | REAL ;

type:
    simple_type 
    {
        curArrayInfo = EMPTY_ARRAY;
    }
    | ARRAY '[' VAL '.' '.' VAL']' OF simple_type
    {
        $$ = ARRAY;
        ArrayInfo info;
        info.startSymbol = $3;
        info.startVal = atoi(symtable[$3].name.c_str());
        info.endSymbol = $6;
        info.endVal = atoi(symtable[$6].name.c_str());
        info.type = $9;
        curArrayInfo = info;
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
        // tablica jako typ zwracany?
        
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
            sym->type = $3;
            sym->token = VAR;
            sym->isGlobal = false;
            sym->isReference = true;
            sym->arrInfo = curArrayInfo;
        }
        paramGrpIds.insert(paramGrpIds.end(), idsList.begin(), idsList.end());
        idsList.clear();
    };

procedure:
    PROC ID
    {
        wrtLbl(symtable[$2].name);
        functionalOffset = 4;
    }
    arguments ';'
    {
        Symbol* proc = &symtable[$2];
        proc->token = PROC;
                
        std::vector<Symbol> args;
        for(auto id : paramGrpIds) {
            Symbol idS = symtable[id];
            args.push_back(newArgument(idS.type, idS.arrInfo));
        }
        proc->arguments = args;

        paramGrpIds.clear();
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
            sym->arrInfo = curArrayInfo;
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
        Symbol sym = symtable[$1];
        int incsp = 0;
        if(sym.token == FUNC) {
            // push result var
            int result = newTemp(sym.type);
            emitPush(symtable[result], newArgument(sym.type, sym.arrInfo));
            incsp += REFSIZE;
            $$ = result;
        }
        if(sym.token == FUNC || sym.token == PROC) {
            emitCall(sym.name);
            if(sym.token == FUNC) {
                newNum(std::to_string(incsp), INT);
                emitIncsp(incsp);
            }    
        }
        
    }
    | ID '(' expression_list ')'
    {
        int id = lookup(symtable[$1].name, FUNC);
        id = (id == -1 ? lookup(symtable[$1].name, PROC) : id);
        if ( id == -1 ) {
            yyerror((symtable[$1].name + " is not callable.").c_str());
            YYERROR;
        }

        Symbol func = symtable[id];
        if(func.arguments.size() < idsList.size()) {
            yyerror(faultyArgsCount(symtable[$1].name, idsList.size(), func.arguments.size(), "many").c_str());
            YYERROR;
        } else if (func.arguments.size() > idsList.size()) {
            yyerror(faultyArgsCount(symtable[$1].name, idsList.size(), func.arguments.size(), "few").c_str());
            YYERROR;
        }

        int incsp = 0;
        for(int id = 0; id < idsList.size(); ++id, incsp += REFSIZE) {
            Symbol given = symtable[idsList[id]];
            Symbol expectedType = func.arguments[id];
            emitPush(given, expectedType);
            
        }
        idsList.clear();
        
        if(func.token == FUNC) {
            // push result var
            int result = newTemp(func.type);
            emitPush(symtable[result], newArgument(func.type, func.arrInfo));
            incsp += REFSIZE;
            $$ = result;
        }

        emitCall(func.name);
        
        newNum(std::to_string(incsp), INT);
        emitIncsp(incsp);
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
                yyerror(faultyArgsCount(symtable[$1].name, idsList.size(), func.arguments.size(), "many").c_str());
                YYERROR;
            } else if (func.arguments.size() > idsList.size()) {
                yyerror(faultyArgsCount(symtable[$1].name, idsList.size(), func.arguments.size(), "few").c_str());
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
        if (symtable[$1].token == FUNC || symtable[$1].token == PROC) {
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
    | ID '[' expression ']' 
    {
        Symbol array = symtable[$1];
        if (array.type != ARRAY) {
            std::string errMsg = "Element '" + array.name + "' is not iterable.";
            yyerror(errMsg.c_str());
            YYERROR;
        }
        ArrayInfo info = array.arrInfo;

        Symbol expr = symtable[$3];
        if (expr.type == ARRAY) {
            std::string errMsg = "Cannot iterate using array.";
            yyerror(errMsg.c_str());
            YYERROR;
        }

        if(expr.type == REAL) {
            int t = newTemp(expr.type);
            Symbol temp = symtable[t];
            emitRealToInt(expr, temp);
            expr = temp;
        }

        // in compile time cannot check if expr value is within arrays indexes

        int index = emitADDOP(expr, SUB, symtable[array.arrInfo.startSymbol]);
        Symbol indexS = symtable[index];
        wrtInstr(
            "mul.i\t" + format(indexS) + ",#4," + format(indexS),
            "mul.i\t" + formatName(indexS.name) + ",#4," + formatName(indexS.name));
        int arrayElement = emitADDOP(array, ADD, indexS);
        symtable[arrayElement].isReference = true;
        $$ = arrayElement;
    }
    ;

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