Repository contains a passing project for TK classes. TK stands for 'Techniki Kompilacji what means Compilation Techniques in Polish.

Project contains a compiler for subset of Pascal language compiled to assembly instructions for 'Harvard Architecture'.
Exemplary compiler with runtime on https://neo.dmcs.pl/tk/web.html

* Program should accept file path (relative or not).

1. read arguments and check if file to read has been passed and file exists
2. use file as input stream
4. parse input stream (file)
5. clean

## TODO:
* error handling (check if variable has been allocated)
* write could be resolved as separate instruction in bison, for example: 'write(' expr ')' {writeToOutput(lookup(ID));}  or something