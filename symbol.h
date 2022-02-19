#include <string>

struct ArrayInfo {
  int startId;
  int stopId;
  int type;           // type of values in array INT/REAL/ARRAY
};

struct Symbol{
  bool isGlobal;
  bool isReference;
  std::string name;   // name of token ('a', 'bis', 'center')
  int token;          // kind of token {ID, FUNCTION, PROCEDURE, VAR}
  int type;           // type of token INT/REAL/ARRAY
  int address;
};