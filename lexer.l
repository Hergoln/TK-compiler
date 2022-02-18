%{
#include "global.h"
#include "parser.hpp"
#include "tokens.h"

int lineno = 1;
%}

%option noyywrap

delim [ \t]
letter [A-Za-z]
digit [0-9]
integer {digit}+
fraction "."{integer}+
number {integer}{fraction}?
id {letter}({letter}|{integer})*

assign ":="
addop "-"|"+"
relop ">"|"<"|">="|"<="|"<>"|"="
mulop "*"|"/"|"div"|"mod"

%%
\r?\n       lineno++;
{delim}     {}

program     {return PROGRAM;}
var         {return VAR;}
integer     {yylval = INT; return INT;}
real        {yylval = REAL; return REAL;}
array       {return ARRAY;}
of          {return OF;}

procedure   {return PROCEDURE;}
function    {return FUNCTION;}
begin       {return BEG;}
end         {return END;}
not         {return NOT;}
or          {return OR;}
and         {return AND;}
if          {return IF;}
then        {return THEN;}
else        {return ELSE;}
do          {return DO;}
while       {return WHILE;}
write       {return WRITE;}
read        {return READ;}

{assign}    {return ASSIGN;}
{addop}     {yylval = maptoopttoken(yytext); return ADDOP;}
{mulop}     {yylval = maptoopttoken(yytext); return MULOP;}
{relop}     {yylval = maptoopttoken(yytext); return RELOP;}

{integer}   {yylval = insert(yytext, VAL, INT); return VAL;}
{number}    {yylval = insert(yytext, VAL, REAL); return VAL;}
{id}        {yylval = insert(yytext, ID, NONE); return ID;}
<<EOF>>     {return DONE;}
.           {return *yytext;}
%%