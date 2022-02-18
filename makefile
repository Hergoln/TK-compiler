comp : symbol.o parser.o lexer.o
	g++ -o comp symbol.o parser.o lexer.o -lfl

lexer.o : lexer.cpp symbol.h global.h
	g++ -c lexer.cpp

lexer.cpp : lexer.l symbol.h 
	flex -o lexer.cpp lexer.l

parser.cpp parser.hpp: parser.y
	bison -o parser.cpp -d parser.y

parser.o : parser.cpp symbol.h global.h
	g++ -c parser.cpp

symbol.o : symbol.cpp symbol.h global.h
	g++ -c symbol.cpp

clean : 
	-rm comp 
	-rm parser.cpp
	-rm lexer.cpp
	-rm *.o