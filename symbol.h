#include <string>
#include <utility>

#define GLOBAL_CONTEXT 1
#define LOCAL_CONTEXT 0

struct ArrayInfo {
  int startAddr;
  int stopAddr;
  int type;           // type of values in array INT/REAL/ARRAY
};

struct Symbol{
  bool isGlobal;
  bool isReference = false;
  std::string name;   // name of token ('a', 'bis', 'center')
  int token;          // kind of token {ID, FUNCTION, PROCEDURE, VAR}
  int type;           // type of token INT/REAL/ARRAY
  int address;
  ArrayInfo arrInfo;
  std::vector<Symbol> arguments;
};