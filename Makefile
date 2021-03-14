M=
# CFLAGS= -O3 -funroll-loops -Ofast
CFLAGS= -funroll-loops -Ofast

all:
	python2 pile.py test*.4th > _test.cc && g++ -std=c++11 $M ${CFLAGS} _test.cc && ./a.out
	: ===========================
	# If passes tests above, check in to RCS, if you have a "ci-l" command.
	test -x /usr/local/bin/ci-l && ci-l `find * -prune -type f -print | grep -v a.out` || echo 'Skipping ci-l'
	: ===========================
	# The following is hardwired for "benchmarks/my-forth-matrix.4th".  Change to your source filename.
	python2 pile.py benchmarks/my-forth-matrix.4th > __m.tmp
	# If clang-format is not available, just cat it.
	# On my Pi 3B+ "Raspbian GNU/Linux 8 (jessie)", I did `apt-get install clang-format-3.9`.
	# Using --style=WebKit allows long lines, which our machine-generated code enjoys.
	clang-format --style=WebKit __m.tmp > _m.cc || /usr/bin/clang-format-3.? --style=WebKit __m.tmp > _m.cc || cat __m.tmp > _m.cc
	g++ -std=c++11 $M ${CFLAGS} _m.cc -lm
	sync
	# fir # # How long should this data file be?
	# fir # dd if=/dev/urandom of=/tmp/0064foo.dat bs=1k count=4096
	# fir # echo 0064foo | ./a.out
	time ./a.out
	time ./a.out
	time ./a.out

# Make with a 32-bit model, for use on x85_64 machines.
#   (* BTW, to be able to use -m32 on x86_64 machines:
#    *     sudo apt-get install gcc-multilib g++-multilib
#    *)
m32:
	make M=-m32 all

clean:
	rm -f a.out __m.tmp _m.cc _test.cc
