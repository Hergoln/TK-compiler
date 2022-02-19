#include "global.h"
#include <iostream>
#include <string>

int verbose = 0;

int main(int argc, char** argv){
  if (argc > 1){
    std::string flag = std::string(argv[1]);
    if (flag == "v" || flag == "verbose")
      verbose = 1;
  }
  initSymtable();

  yyparse();
  if(!errRaised) {
    printf("Compilation successful!!\n"); 
  }

  if(verbose) {   
    printf("Printout of symbols table:\n");
    prntSymtable();
  }

  std::string outfname = "out.asm";

  std::cout << std::endl << "Dumping compiled file:" << std::endl << std::endl;
  if(verbose) {
    dumpToFile(outfname);
  }
};