comp : symbol.o parser.o lexer.o main.o
	g++ -o comp symbol.o parser.o lexer.o emit.o main.o -lfl

lexer.o : lexer.cpp symbol.h global.h
	g++ -c lexer.cpp

lexer.cpp : lexer.l symbol.h 
	flex -o lexer.cpp lexer.l

parser.cpp parser.hpp: parser.y
	bison -o parser.cpp -d parser.y

parser.o : parser.cpp emit.o symbol.h global.h
	g++ -c parser.cpp

emit.o : emit.cpp global.h
	g++ -c emit.cpp

symbol.o : symbol.cpp symbol.h global.h parser.hpp
	g++ -c symbol.cpp

main.o : main.cpp global.h
	g++ -c main.cpp

clean : 
	-rm comp 
	-rm parser.cpp
	-rm parser.hpp
	-rm lexer.cpp
	-rm *.o