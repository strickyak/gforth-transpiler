M=

all:
	python2 mkprims.py < prims.txt ; head -999 _defs.h _decls.h _words.tmp _colons.tmp
	python2 pile.py test*.4th > _test.cc && cat -n _test.cc && g++ $M -g _test.cc && ./a.out
	: ===========================
	# If passes tests above, check in to RCS, if you have a "ci-l" command.
	test -x /usr/local/bin/ci-l && ci-l `find * -prune -type f -print | grep -v a.out`
	: ===========================
	# The following is hardwired for "fir.4th".  Change to your source filename.
	python2 pile.py fir.4th > __fir.tmp
	clang-format --style=WebKit __fir.tmp > _fir.cc
	g++ $M -g _fir.cc -lm
	# How long should this data file be?
	dd if=/dev/random of=/tmp/0064foo.dat bs=1k count=4096
	echo 0064foo | ./a.out

# Make with a 32-bit model, for use on x85_64 machines.
#   (* BTW, to be able to use -m32 on x86_64 machines:
#    *     sudo apt-get install gcc-multilib g++-multilib
#    *)
m32:
	make M=-m32 all

clean:
	rm -f a.out __fir.tmp _fir.cc _test.cc _colons.tmp _decls.h _defs.h _words.tmp
