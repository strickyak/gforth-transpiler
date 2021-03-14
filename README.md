# gforth-transpiler
Translate gforth source code into C++, for a subset of gforth.

Not 100% compatible with gforth.  YMMV.

## Quick Usage:

Create your FORTH file `program.4th`

Run `make program` to compile and build a binary named `program`.
Run `make CXXFLAGS="..." program` to add any compiler flags.
You can also add `CXX=clang` to use clang instead of g++.

Type `make program.cc` to compile into intermediate `program.cc`.
Then you can use any C++ compiler with any options you want.  You can use `-g`
and a debugger.

## Internals

Everything needed to build the C++ program is in one file: `pile.py`
which uses Python2.

What would ordinarily belong in a header file `vm.h` is now built into
`pile.py`.  Definitions of FORTH primatives, which use a unique file
format, are also now in `pile.py`.

It works with g++ or clang for the C++ compiler.

If you compile with -D"DEBUG" it become quite verbose and also enables
a bunch of asserts.
