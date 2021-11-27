# gforth-transpiler
Translate gforth source code into C++, for a subset of gforth.

This project was created to speed up one specific target Forth program,
and it only supports the exact words that were used in that program.
Because we chose a structure based on those limitations, there are many
GForth words that are difficult or impossible to add to this forth.
And there are many GForth words that could be added easily.  It just
depends on the word, and whether the word breaks any of our assumptions
and simplifications.

(That target program is a Finite Impulse Response filter written by Andy
Korask (KR6DD) for a digital signal processing role on a Raspberry Pi 3b.
The work-in-progress is not public yet.  It is floating-point intensive,
and should benefit from SIMD (Single Instructions Multiple Data) hardware
instructions, but we are not attempting that.)

However I have some tests and benchmarks in the repo that work, and they
are representative of the kind of operations in the target program.

## Quick Usage:

For the quickest demo, see section `Just Type make` below.

Create your FORTH file `program.4th`

Run `make program` to compile and build a binary named `program`.
Run `make CXXFLAGS="..." program` to add any compiler flags.  Notice you
might need `-std=c++11` in CXXFLAGS.  You can also add `CXX=clang`
to use clang instead of g++.

Type `make program.cc` to compile into intermediate `program.cc`.
Then you can use any C++ compiler with any options you want.  You can use
`-g` and a debugger.

To run the transpiler without using `make`, it's this simple:
```
$ python2 pile.py program.4th > program.cc
```

## Internals

Everything needed to build the C++ program is in one file: `pile.py`
which uses Python2.

What would ordinarily belong in a header file `vm.h` is now built into
`pile.py`, in the variable `VM_HEADER`.  Definitions of FORTH primitives,
which use a unique file format, are also now in `pile.py` in the variable
`PRIM_DEFINITIONS`.  The body of these definitions is in C++, but some
boilerplate gets emitted to wrap your C++ body in a C++ function.

It works with g++ or clang for the C++ compiler.

If you compile with -D"DEBUG" it become quite verbose and also enables
a bunch of asserts.

This forth uses 4 stacks:

*  "data" -- the usual Forth stack for arguments and results

*  "return" -- Not actually used for return addresses, but it is used
               for DO loops to store the Limit and current Index.
               This limitation coud break some standard GForth usage!

*  "floating" -- like in GForth, there is a separate stack for
                 floating point numbers.

*  "C++ Stack"  -- Calling words is done by calling C++ functions,
                 so return adresses are in the C++ stack, the hardware
                 stack of the processor.

This is designed so that the generated code looks somewhat like idiomatic
C++, the kind that optimizing compilers are designed to handle well.

## Unique Words

Some unique words in this Forth that are used in tests:

```
must   (bool -- )   Like assert, it crashes if the argument is zero.

~      ( -- )       Asserts that all stacks (data, "return", and
                    floating-point) are empty.  This is usually the
                    last word in a test.
```

## Just Type `make`

```
$ git clone https://github.com/strickyak/gforth-transpiler.git
Cloning into 'gforth-transpiler'...
remote: Enumerating objects: 191, done.
remote: Counting objects: 100% (191/191), done.
remote: Compressing objects: 100% (129/129), done.
remote: Total 191 (delta 117), reused 134 (delta 62), pack-reused 0
Receiving objects: 100% (191/191), 39.68 KiB | 461.00 KiB/s, done.
Resolving deltas: 100% (117/117), done.

$ cd gforth-transpiler/

$ make clean
rm -f a.out ./benchmarks/my-forth-matrix ./test1

$ make
python2 pile.py test1.4th > test1.cc
g++ -Ofast -funroll-loops -std=c++11   -c -o test1.o test1.cc
test1.cc: In function ‘int main(int, const char**)’:
test1.cc:3255:39: warning: right shift count >= width of type [-Wshift-count-overflow]
 3255 |                 push( (word)(123456LL >> (8*sizeof(word))) ); // high half of double-int <<< 123456. >>>
      |                              ~~~~~~~~~^~~~~~~~~~~~~~~~~~~
test1.cc:3314:39: warning: right shift count >= width of type [-Wshift-count-overflow]
 3314 |                 push( (word)(123456LL >> (8*sizeof(word))) ); // high half of double-int <<< 123.456 >>>
      |                              ~~~~~~~~~^~~~~~~~~~~~~~~~~~~
test1.cc:3373:39: warning: right shift count >= width of type [-Wshift-count-overflow]
 3373 |                 push( (word)(123456LL >> (8*sizeof(word))) ); // high half of double-int <<< .123456 >>>
      |                              ~~~~~~~~~^~~~~~~~~~~~~~~~~~~
test1.cc:3432:51: warning: right shift count >= width of type [-Wshift-count-overflow]
 3432 |                 push( (word)(123456789123456789LL >> (8*sizeof(word))) ); // high half of double-int <<< 123456789123456789. >>>
      |                              ~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~
test1.cc:3588:51: warning: right shift count >= width of type [-Wshift-count-overflow]
 3588 |                 push( (word)(123456789123456789LL >> (8*sizeof(word))) ); // high half of double-int <<< 123456789123456789. >>>
      |                              ~~~~~~~~~~~~~~~~~~~~~^~~~~~~~~~~~~~~~~~~
cc   test1.o  -lm -o test1
./test1
0 0.841470984807897 0.00159265291648683 1 0.54030230586814 -0.99999873172754
((( pi=3.14159265358979 sin(pi/4)=0.707106781186547 )))
49 50 51 52 53 54 55 56 12849 13363 13877 14391 (Intel Order) 42 0 42 42 1 2 3 4 5 6 7 8 9 10
1 4 9 16 25 36 49 64 81 100
0 2 4 6 8
0 1 2 9 4 25 6 49 8 81
. . .
Excellent ! ! !
python2 pile.py benchmarks/my-forth-matrix.4th > benchmarks/my-forth-matrix.cc
g++ -Ofast -funroll-loops -std=c++11   -c -o benchmarks/my-forth-matrix.o benchmarks/my-forth-matrix.cc
cc   benchmarks/my-forth-matrix.o  -lm -o benchmarks/my-forth-matrix
python2 pile.py benchmarks/dot-product-c.4th > benchmarks/dot-product-c.cc
g++ -Ofast -funroll-loops -std=c++11   -c -o benchmarks/dot-product-c.o benchmarks/dot-product-c.cc
cc   benchmarks/dot-product-c.o  -lm -o benchmarks/dot-product-c
python2 pile.py benchmarks/dot-product-colon.4th > benchmarks/dot-product-colon.cc
g++ -Ofast -funroll-loops -std=c++11   -c -o benchmarks/dot-product-colon.o benchmarks/dot-product-colon.cc
cc   benchmarks/dot-product-colon.o  -lm -o benchmarks/dot-product-colon
time benchmarks/my-forth-matrix
side_effect=16778890.1295335
4.74user 0.00system 0:04.74elapsed 100%CPU (0avgtext+0avgdata 1560maxresident)k
0inputs+0outputs (0major+78minor)pagefaults 0swaps
time benchmarks/dot-product-c
answer=333832500000000
0.51user 0.00system 0:00.51elapsed 100%CPU (0avgtext+0avgdata 1572maxresident)k
0inputs+0outputs (0major+81minor)pagefaults 0swaps
time benchmarks/dot-product-colon
answer=333832500000000
2.37user 0.00system 0:02.37elapsed 99%CPU (0avgtext+0avgdata 1460maxresident)k
0inputs+0outputs (0major+76minor)pagefaults 0swaps
rm -f a.out ./benchmarks/my-forth-matrix ./test1
rm benchmarks/my-forth-matrix.o benchmarks/dot-product-colon.cc benchmarks/my-forth-matrix.cc test1.o benchmarks/dot-product-c.o benchmarks/dot-product-c.cc test1.cc benchmarks/dot-product-colon.o

$
```

## Sample Benchmark

This one trial was done on a `x86_64 GNU/Linux` laptop under uncontrolled conditions.

```
$ make benchmarks/my-forth-matrix
python2 pile.py benchmarks/my-forth-matrix.4th > benchmarks/my-forth-matrix.cc
g++ -Ofast -funroll-loops -std=c++11   -c -o benchmarks/my-forth-matrix.o benchmarks/my-forth-matrix.cc
cc   benchmarks/my-forth-matrix.o  -lm -o benchmarks/my-forth-matrix
rm benchmarks/my-forth-matrix.o benchmarks/my-forth-matrix.cc

$ time benchmarks/my-forth-matrix
side_effect=16778890.1295335

real	0m6.233s
user	0m6.230s
sys	0m0.003s

$ time benchmarks/my-forth-matrix
side_effect=16778890.1295335

real	0m6.209s
user	0m6.200s
sys	0m0.007s


$ time gforth benchmarks/my-forth-matrix.4th
side_effect=16778890.1295335

real	0m42.759s
user	0m42.745s
sys	0m0.003s

$ time gforth-fast benchmarks/my-forth-matrix.4th
side_effect=16778890.1295335

real	0m21.220s
user	0m21.180s
sys	0m0.044s

$ time gforth-fast benchmarks/my-forth-matrix.4th
side_effect=16778890.1295335

real	0m20.567s
user	0m20.532s
sys	0m0.043s

$
```

That's a 6.9x speedup to gforth, and a 3.3x speedup to gforth-fast.

```
$ go run go/src/github.com/strickyak/livy-apl/livy.go
      42.759 div 6.209
6.886616202287003
      20.567 / 6.209
3.312449669834112
      *EOF*

$
```
