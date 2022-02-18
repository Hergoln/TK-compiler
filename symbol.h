#ifndef INCLUDE_H

#define INCLUDE_H

#include <string>

enum vartype {none, integer, real};

struct Symbol{
  std::string name;        // name of token ('a', 'bis', 'center')
  int token;               // kind of token {ID, FUNCTION, ...}
  vartype type;            // type of token INT/REAL
};

#endif