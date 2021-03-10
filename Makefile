M=

all:
	python mkdefs.py < defs.txt ; head -999 defs.h decls.h words.tmp
	python pile.py test*.4th > z.cc && cat -n z.cc && g++ $M -g z.cc && ./a.out
	: ===========================
	ci-l `find * -prune -type f | grep -v a.out`
	: ===========================
	python pile.py fir.4th > _fir.cc
	clang-format --style=WebKit _fir.cc > __fir.cc
	g++ $M -g __fir.cc -lm
	dd if=/dev/random of=/tmp/0064foo.dat bs=1k count=4096
	echo 0064foo | ./a.out

m32:
	make M=-m32 all

# BTW, for m32:
#   sudo apt-get install gcc-multilib 
#   sudo apt-get install g++-multilib 
