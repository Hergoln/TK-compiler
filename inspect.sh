#!/bin/bash
make
echo "Inspection of file $1"
echo ""
./comp < $1 v