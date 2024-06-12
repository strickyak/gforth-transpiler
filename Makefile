# If you have a source file named my-stuff.4th
# you can compile the binary like this
#   make my-stuff
# and run it like this
#   ./my-stuff

CXXFLAGS=-Ofast -funroll-loops -std=c++11
LDLIBS= -lm
PILE = parpile

%.cc : %.4th $(PILE).py
	python3 $(PILE).py $< > $@

all: test benchmark clean

test: test1 whitespace-regress-test
	./test1

whitespace-regress-test: whitespace-regress-test.4th
	python2 pile.py $< >/dev/null

benchmark: benchmarks/my-forth-matrix benchmarks/dot-product-c benchmarks/dot-product-colon
	time benchmarks/my-forth-matrix
	time benchmarks/dot-product-c
	time benchmarks/dot-product-colon

m32:
	make 'CXXFLAGS=-Ofast -funroll-loops -std=c++11 -m32' LDFLAGS=-m32

debug:
	make 'CXXFLAGS=-g -std=c++11 -DDEBUG'

clean:
	rm -f a.out ./benchmarks/my-forth-matrix ./test1

.PHONY: all test benchmark clean whitespace-regress-test
