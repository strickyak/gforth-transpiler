# If you have a source file named my-stuff.4th
# you can compile the binary like this
#   make my-stuff
# and run it like this
#   ./my-stuff

CXXFLAGS=-Ofast -funroll-loops 

%.cc : %.4th pile.py
	python2 pile.py $< > $@

all: test benchmark clean

test: test1
	./test1

benchmark: benchmarks/my-forth-matrix
	time ./benchmarks/my-forth-matrix

clean:
	rm -f a.out ./benchmarks/my-forth-matrix ./test1

.PHONY: all test benchmark clean
