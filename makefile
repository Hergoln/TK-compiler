comp : parser.hpp tokens.o parser.o symbol.o lexer.o emit.o main.o
	g++ -o comp symbol.o parser.o tokens.o lexer.o emit.o main.o -lfl

lexer.o : lexer.cpp global.h
	g++ -c lexer.cpp

lexer.cpp : lexer.l global.h
	flex -o lexer.cpp lexer.l

parser.cpp parser.hpp: parser.y
	bison -o parser.cpp -d parser.y

parser.o : parser.cpp global.h
	g++ -c parser.cpp

emit.o : emit.cpp global.h
	g++ -c emit.cpp

symbol.o : symbol.cpp global.h
	g++ -c symbol.cpp

main.o : main.cpp global.h
	g++ -c main.cpp

tokens.o : tokens.cpp global.h
	g++ -c tokens.cpp

clean : 
	-rm comp 
	-rm parser.cpp
	-rm parser.hpp
	-rm lexer.cpp
	-rm *.o