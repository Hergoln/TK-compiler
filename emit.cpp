#include "global.h"
#include <sstream>

std::stringstream outb;

void wrtInstr (std::string instr, std::string repr) {
  outb << "\t" << instr << "\t;" << repr << std::endl;
}

void wrtLbl (std::string label) {
  outb << label + ":" << std::endl;
}

void dumpToFile(std::string fname) {
  std::cout << outb.str() << std::endl;
}