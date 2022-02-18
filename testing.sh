#!/bin/bash
make

echo "Test suite"

for i in `ls ./tests`; do
  echo ''
  echo "Compiling $i"
  ./comp < "tests/$i"
done