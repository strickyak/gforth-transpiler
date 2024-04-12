import re, sys

VM_HEADER = r'''
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#include <cassert>
#include <cerrno>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctgmath>

#ifdef DEBUG
#define SAY fprintf
#else
#define SAY if(0)fprintf
#endif

using word = long;
using uword = unsigned long;
constexpr int HEAP_SIZE = 100 * 1000 * 1000;  // 100M
constexpr int STACK_SIZE = 1000;

char heap[HEAP_SIZE];
word here;  // pointer

word dp, rp, fp;      // stack pointers
word ds[STACK_SIZE];  // data stack
word rs[STACK_SIZE];  // return stack
double fs[STACK_SIZE];  // floating stack

inline word BOOL(word x) { return x? -1 : 0; }

inline void push(word a) { ds[++dp] = a; }
inline word pop() { return ds[dp--]; }
inline void pushb(word a) { ds[++dp] = BOOL(a); }

inline void rpush(word a) { rs[++rp] = a; }
inline word rpop() { return rs[rp--]; }

inline void fpush(double a) { fs[++fp] = a; }
inline double fpop() { return fs[fp--]; }

void LongLongToPair(long long x, word* hi, word* lo) {
  if (sizeof(word) == 8) {
    *hi = 0; *lo = (word)x;
  } else {
    *hi = (word)(x>>32); *lo = (word)x;
  }
}
long long PairToLongLong(word hi, word lo) {
  if (sizeof(word) == 8) {
    return lo;
  } else {
    return ((long long)hi << 32) | (0xFFFFFFFF & (long long)lo);
  }
}

void VMInitialize() {
  SAY(stderr, "sizeof (int) = %d\n", sizeof(int));
  SAY(stderr, "sizeof (word) = %d\n", sizeof(word));
  SAY(stderr, "sizeof (uword) = %d\n", sizeof(uword));
  SAY(stderr, "sizeof (long) = %d\n", sizeof(long));
  SAY(stderr, "sizeof (char*) = %d\n", sizeof(char*));
  SAY(stderr, "sizeof (word*) = %d\n", sizeof(word*));

  here = (word)(&heap[0]);
  SAY(stderr, "=== here = %ld\n", here);
}

void ShowStacks() {
#ifdef DEBUG
  SAY(stderr, "\t\t\t[[[ ");
  for (word i=1; i<=dp; i++) SAY(stderr, "%ld ", ds[i]);
  SAY(stderr, ";;; ");
  for (word i=1; i<=rp; i++) SAY(stderr, "0x%lx ", rs[i]);
  SAY(stderr, ";;; ");
  for (word i=1; i<=fp; i++) SAY(stderr, "%.12g ", fs[i]);
  SAY(stderr, "]]] ...... %d %d %d\n", dp, rp, fp);
  assert(dp >= 0);
  assert(rp >= 0);
  assert(fp >= 0);
  assert(dp < 100);
  assert(rp < 100);
  assert(fp < 100);
#endif
}
'''

PRIM_DEFINITIONS = r'''
# Builtin FORTH word definitions (except for defining words
# and string literals handled in pile.py).
#
# Clauses start when one of the following words in in column 1.
# The body of each clause must be indented, with space in column 1.
#
# def -- raw C++; must manipulate stacks manually.
# : -- defined in terms of forth words.
#
# Special forms that manipulate the stack for you:
#
# un -- unary function computes word z given word a.
# bin -- binary function computes word z given word a & word b.
# fun -- binary function computes double z given double a & double b
#          ( that is, C double float;  not forth "d" double int ).
# fbin -- binary function computes double z given double a & double b.
# fbinw -- binary function computes word z given double a & double b.
#
# See vm.h for more about stacks.
#

def fconvolve ( post_incr_ptr pre_decr_ptr n -- | -- result )

  word n = pop();               // number of terms (i.e. #taps-1)
  double* p2 = (double*)pop();  // pre-decrementing pointer
  double* p1 = (double*)pop();  // post-incrementing pointer

  double result = 0.0;
  for (word i = 0; i<n; i++) {
    result += *(p1++) * *(--p2);
  }
  fpush(result);

def f64_dot_product ( in_fp1 in_fp2 n -- | -- result )

  word n = pop();
  double* in_fp2 = (double*)pop();
  double* in_fp1 = (double*)pop();

  double result = 0.0;
  for (word i = 0; i<n; i++) {
    result += in_fp1[i] * in_fp2[i];
  }
  fpush(result);

def utime
  struct timeval tv;
  gettimeofday(&tv, nullptr);
  long long x = 1000000 * (long long)tv.tv_sec + (long long)tv.tv_usec;
  word a, b;
  LongLongToPair(x, &b, &a);
  push(a); push(b);
def cmove ( p q n - )
  word len = pop();
  char* to = (char*)pop();
  char* from = (char*)pop();
  for (word i=0; i<len; i++) to[i] = from[i];

def true ( - z )
  push(-1);
def false ( - z )
  push(0);
un 0<>
  z = BOOL(a != 0);

un w@
  unsigned short* p= (unsigned short*)a;
  z = (word)*p;
un uw@
  unsigned short* p= (unsigned short*)a;
  z = (word)*p;
un sw@
  signed short* p= (signed short*)a;
  z = (word)*p;
def w!
  unsigned short* p= (unsigned short*)pop();
  unsigned short x = (unsigned short)(0xFFFF & pop());
  *p = x;

def d- ( a b c d - x y )
  word d = pop();
  word c = pop();
  word b = pop();
  word a = pop();
  long long z = PairToLongLong(b,a) - PairToLongLong(d,c);
  word x, y;
  LongLongToPair(z, &y, &x);
  push(x);
  push(y);
def 2swap ( a b c d - c d a b )
  word d = pop();
  word c = pop();
  word b = pop();
  word a = pop();
  push(c);
  push(d);
  push(a);
  push(b);
def */ ( a b c - z )
  word c = pop();
  word b = pop();
  word a = pop();
  long long x = (long long)a * (long long)b;
  x = x / (long long)c;
  word z = (word)x;
  assert(x == z);
  push(z);
def break:
  abort();
def s>f ( a - | - x )
  word x = pop();
  fpush((double)x);
def f>s ( a - | - x )
  double x = fpop();
  push ((word)x);
fun fnegate
  z = -a;
un negate
  z = -a;
un abs
  z = (a<0) ? -a : a;
fun fabs     //   20210323
  z = (a<0) ? -a : a;
bin min
  z = (a<b) ? a : b;
bin max
  z = (a<b) ? b : a;
def d0>
  word hi = pop();
  word lo = pop();
  long long x = PairToLongLong(hi, lo);
  push (x > 0);

def d. ( lo hi - )
  word hi = pop();
  word lo = pop();
  long long x = PairToLongLong(hi, lo);
  printf("%lld ", x);
    fflush(stdout);
def throw
  word x = pop();
  if (x) abort();
def type
  word len = pop();
  char* addr = (char*)pop();
  for (int i = 0; i < len; i++) putchar(addr[i]);
def emit
  word x = pop(); // ajk 20220731
  putchar(x);
def count
  char* addr = (char*)pop();
  word len = 255 & (word)(*addr);
  push((word)addr+1);
  push(len);

def bye
  exit(0);
def quit
  exit(0);
def 2drop ( a b - )
  dp -= 2;
def 2dup ( a b - a b a b )
  word a = ds[dp-1];
  word b = ds[dp];
  push(a);
  push(b);
def f2dup ( a b - a b a b )
  double a = fs[fp-1];
  double b = fs[fp];
  fpush(a);
  fpush(b);
def 3dup ( a b - a b a b )
  word a = ds[dp-2];
  word b = ds[dp-1];
  word c = ds[dp];
  push(a);
  push(b);
  push(c);
def f3dup ( a b - a b a b )
  double a = fs[fp-2];
  double b = fs[fp-1];
  double c = fs[fp];
  fpush(a);
  fpush(b);
  fpush(c);
def d>s ( lo hi - lo )
  word hi = pop();
  word lo = pop();
  long long x = PairToLongLong(hi, lo);
  push((word)x);
def s>d
  word x = pop();
  word hi, lo;
  LongLongToPair((long long)x, &hi, &lo);
  push(lo);
  push(hi);

def s>unumber?
  word len = pop();
  char* addr = (char*)pop();
  char* buffer = (char*)malloc(len+1);
  memset(buffer, 0, len+1);
  memcpy(buffer, addr, len);
  word x = atoi(buffer);
  free(buffer);
  push(x);  // lo
  push(x<0 ? -1 : 0);  // hi
  push(BOOL(1));
def c@
  char* addr = (char*)pop();
  word ch = 255 & (word)(*addr);
  push(ch);
def c!
  char* addr = (char*)pop();
  word ch = pop();
  *addr = (char)ch;
def accept
  word max_len = pop();
  char* buffer = (char*) pop();
  memset(buffer, 0, max_len);
  char* ok = fgets(buffer, max_len-1, stdin);
  assert(ok);
  int n = strlen(buffer);
  if (buffer[n-1] == '\n') buffer[n-1] = '\0';
  push(strlen(buffer));

def +place
  char* whither = (char*) pop();
  word len = pop();
  assert(len < 256);
  char* whence = (char*) pop();
  word old_len = whither[0];
  assert(len + old_len < 256);
  whither[0] = len + old_len;
  for (word i = 0; i < len; i++) whither[i+old_len+1] = whence[i];

def place
  char* whither = (char*) pop();
  word len = pop();
  assert(len < 256);
  char* whence = (char*) pop();
  whither[0] = len;
  for (word i = 0; i < len; i++) whither[i+1] = whence[i];

def decimal
  {}  // always in decimal, for now.
def open-file
  pop(); // how
  word n = pop();
  char* a = (char*) pop();

  char* fname = (char*) malloc(n+1);
  memset(fname, 0, n+1);
  memcpy(fname, a, n);

  FILE* fd = fopen(fname, "r");
  SAY(stderr, "=== open-file: `%s` => %ld, %d\n", fname, (word)fd, errno);
  free(fname);
  if (fd) { // good
    push((word)fd);
    push(0);
  } else { // err
    push(0);
    push(errno? errno: 255); // nonzero
  }
def open-pipe
  word how = pop(); // how
  assert(how == O_RDONLY);
  word n = pop();
  char* a = (char*) pop();

  char* fname = (char*) malloc(n+1);
  memset(fname, 0, n+1);
  memcpy(fname, a, n);

  FILE* fd = popen(fname, "r");
  SAY(stderr, "=== open-pipe: `%s` => %ld, %d\n", fname, (word)fd, errno);
  free(fname);
  if (fd) { // good
    push((word)fd);
    push(0);
  } else { // err
    push(0);
    push(errno? errno: 255); // nonzero
  }
def create-file
  pop(); // how
  word n = pop();
  char* a = (char*) pop();

  char* fname = (char*) malloc(n+1);
  memset(fname, 0, n+1);
  memcpy(fname, a, n);

  FILE* fd = fopen(fname, "w");
  SAY(stderr, "=== create-file: `%s` => %ld, %d\n", fname, (word)fd, errno);
  free(fname);
  if (fd) { // good
    push((word)fd);
    push(0);
  } else { // err
    push(0);
    push(errno? errno: 255); // nonzero
  }
def delete-file
  word n = pop();
  char* a = (char*) pop();

  char* fname = (char*) malloc(n+1);
  memset(fname, 0, n+1);
  memcpy(fname, a, n);

  SAY(stderr, "=== delete-file: `%s`\n", fname);
  int e = unlink(fname);
  if (e) {
          perror("because");
          fprintf(stderr, "Could not delete `%s`\n", fname);
          push(errno? errno: 255);
  } else {
          push(0);
  }
  free(fname);

def read-file
  FILE* file = (FILE*)pop();
  word len = pop();
  char* addr = (char*)pop();
  size_t n = fread(addr, 1, len, file);
  push(n);  // num bytes read
  if (n>0) {
    push(0);    // wior GOOD
  } else {
    push(errno? errno: 255); // wior BAD
  }
def write-file
  FILE* file = (FILE*)pop();
  word len = pop();
  char* addr = (char*)pop();
  size_t n = fwrite(addr, 1, len, file);
  if (n==len) {
    push(0);
  } else {
    push(errno? errno: 255);
  }
def close-file
  FILE* file = (FILE*)pop();
  fclose(file);
  push(0);
def file-size
  FILE* file = (FILE*)pop();
  int fd = fileno(file);
  struct stat st{};
  int e = fstat(fd, &st);
  if (e) {
    push(-1);
    push(-1);
    push(errno);
  } else {
    word sz = (word)st.st_size;
    push(sz);
    push(0);
    push(0);
  }

def r/o
  ds[++dp] = O_RDONLY;
def r/w
  ds[++dp] = O_RDWR | O_CREAT;
def erase
  word n = pop();
  char* p = (char*) pop();
  SAY(stderr, "=== erase: %ld bytes at %ld\n", n, (word)p);
  memset(p, 0, (size_t)n);
def falign
  here = ~(word)(7) & (here + 7);
#un fcells
#  z = 8 * a;
def allot
  SAY(stderr, "=== pre-allot: here = %ld\n", here);
  word len = pop();
  word z = here;
  here += len;
  SAY(stderr, "=== post-allot: here = %ld\n", here);
#def i
#  ds[++dp] = rs[rp];
#def j
#  ds[++dp] = rs[rp-2];
def must
  if (0 == ds[dp--]) {
    fflush(stdout);
    SAY(stderr, "\n****** FAILURE IN must ******\n");
    fflush(stderr);
    abort();
  }
def ~
  if (dp) {
    fflush(stdout);
    SAY(stderr, "\ndp is %ld want 0\n", dp);
    fflush(stderr);
    abort();
  }
  if (rp) {
    fflush(stdout);
    SAY(stderr, "\nrp is %ld want 0\n", rp);
    fflush(stderr);
    abort();
  }
  if (fp) {
    fflush(stdout);
    SAY(stderr, "\nfp is %ld want 0\n", fp);
    fflush(stderr);
    abort();
  }
def . ( a - )
  printf("%ld ", ds[dp--]);
    fflush(stdout);
def f. ( - | f - )
  printf("%.15g ", fs[fp--]);
    fflush(stdout);
def cr ( - )
  printf("\n");
    fflush(stdout);
def dup ( a - a a )
  dp++;
  ds[dp] = ds[dp-1];

def over ( a b - a b a )
  dp++;
  ds[dp] = ds[dp-2];
def swap ( a b - b a )
  word tmp = ds[dp];
  ds[dp] = ds[dp-1];
  ds[dp-1] = tmp;
def rot ( a b c - b c a )
  word tmp = ds[dp-2];
  ds[dp-2] = ds[dp-1];
  ds[dp-1] = ds[dp];
  ds[dp] = tmp;
def -rot ( a b c - c a b )
  word tmp = ds[dp];
  ds[dp] = ds[dp-1];
  ds[dp-1] = ds[dp-2];
  ds[dp-2] = tmp;

def fover ( a b - a b a )
  fp++;
  fs[fp] = fs[fp-2];
def fswap ( a b - b a )
  double tmp = fs[fp];
  fs[fp] = fs[fp-1];
  fs[fp-1] = tmp;
def frot ( a b c - b c a )
  double tmp = fs[fp-2];
  fs[fp-2] = fs[fp-1];
  fs[fp-1] = fs[fp];
  fs[fp] = tmp;
def f-rot ( a b c - c a b )
  double tmp = fs[fp];
  fs[fp] = fs[fp-1];
  fs[fp-1] = fs[fp-2];
  fs[fp-2] = tmp;

def ! ( x p - )
  word* p = (word*)ds[dp--];
  *p = ds[dp--];
def @ ( p - x )
  word* p = (word*)ds[dp];
  ds[dp] = *p;
def f!
  double* p = (double*)ds[dp--];
  *p = fs[fp--];
def f@
  double* p = (double*)pop();
  fpush(*p);
def d>f
  word hi = pop();
  word lo = pop();
  long long x = PairToLongLong(hi, lo);
  fpush((double)x);
def f>d
  double a = fpop();
  long long b = (long long)a;
  word hi, lo;
  LongLongToPair(b, &hi, &lo);
  push(lo);
  push(hi);
def drop ( a - )
  --dp;
def 2@
  word* a = (word*)ds[dp];
  ds[dp] = a[1];
  ds[++dp] = a[0];
un cells
  z = sizeof(word) * a;
un 0=
  z = BOOL(a==0);
un 1+
  z = a+1;
un 1-
  z = a-1;
bin =
  z = BOOL(a == b);
bin <>
  z = BOOL(a != b);
bin /=
  z = BOOL(a != b);
bin <
  z = BOOL(a < b);
bin <=
  z = BOOL(a <= b);
bin >
  z = BOOL(a > b);
bin >=
  z = BOOL(a >= b);
bin u<
  z = BOOL((uword)a < (uword)b);
bin u<=
  z = BOOL((uword)a <= (uword)b);
bin u>
  z = BOOL((uword)a > (uword)b);
bin u>=
  z = BOOL((uword)a >= (uword)b);
bin and
  z = a & b;
bin or
  z = a | b;
bin xor
  z = a ^ b;
bin +
  z = a + b;
bin -
  z = a - b;
bin *
  z = a * b;
bin /
  assert(b != 0);
  z = a / b;
bin mod
  assert(b > 0);
  z = ((a % b) + b) % b;
def fdrop
  fp--;   // kr6dd 20210815
def fdup
  fs[fp+1] = fs[fp];
  fp++;
fbin f+
  z = a + b;
fbin f-
  z = a - b;
fbin f*
  z = a * b;
fbin f/
  z = a / b;
fbin f**
  z = pow(a, b);
fbinw f=
  z = (a == b);
fbinw f/=
  z = (a != b);
fbinw f<>
  z = (a != b);
fbinw f<
  z = (a < b);
fbinw f<=
  z = (a <= b);
fbinw f>
  z = (a > b);
fbinw f>=
  z = (a >= b);
fun fsin
  z = sin(a);
fun fcos
  z = cos(a);
fun ftan
  z = tan(a);
fun fasin
  z = asin(a);
fun facos
  z = acos(a);
fun fatan
  z = atan(a);
fun flog
  z = log(a);
fun fexp
  z = exp(a);
'''

DEFINED_WORDS = set()

def Esc(s):
    z = ''
    for ch in s:
        if '0' <= ch <= '9': z += ch
        elif 'A' <= ch <= 'Z': z += ch
        elif 'a' <= ch <= 'z': z += ch
        else:
            z += '_%d_' % ord(ch)
    return z

def ParseSignature(vec):
    if not vec:
        return None, None, None, None
    assert vec[0] == '('
    assert vec[-1] == ')'
    vec = vec[1:-1]   # Trim ( and )
    win, wout, fin, fout = [], [], [], []
    floating, outputting = False, False
    for e in vec:
        if e == '|':
            floating = True
            outputting = False
        elif e == '-':
            outputting = True
        else:
            if floating:
                if outputting:
                    fout.append(e)
                else:
                    fin.append(e)
            else:
                if outputting:
                    wout.append(e)
                else:
                    win.append(e)
    return win, wout, fin, fout

class InMemoryFile(object):
    def __init__(self):
        self.fragments = []

    def write(self, s):
        self.fragments.append(s)

    def __str__(self):
        return ''.join(self.fragments)

    def close(self):
        pass

Decls = InMemoryFile()
Defs = InMemoryFile()

def CompilePrims(prim_defs):
    fd = Defs

    ender = ''
    for line in prim_defs.split('\n'):
        line = line.rstrip()
        cmd = line.split()[0] if line.split() else '**empty**'
        if line.startswith('#'):
            pass
        elif cmd == 'def':
            name = line.split()[1]
            DEFINED_WORDS.add(name)
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, 'inline void F_%s() { // %s' % (nom, name)
            ender = '}'
            fd = Defs
            sig = ParseSignature(line.split()[2:])
        elif cmd == 'bin':
            name = line.split()[1]
            DEFINED_WORDS.add(name)
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, '''inline void F_%s() { // %s'
              word a = ds[dp-1];
              word b = ds[dp];
              word z = 0;
              ''' % (nom, name)
            ender = 'ds[--dp] = z; }'
            fd = Defs
        elif cmd == 'un':
            name = line.split()[1]
            DEFINED_WORDS.add(name)
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, '''inline void F_%s() { // %s'
              word a = ds[dp];
              word z = 0;
              ''' % (nom, name)
            ender = 'ds[dp] = z; }'
            fd = Defs
        elif cmd == 'fun':
            name = line.split()[1]
            DEFINED_WORDS.add(name)
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, '''inline void F_%s() { // %s'
              double a = fs[fp];
              double z = 0;
              ''' % (nom, name)
            ender = 'fs[fp] = z; }'
            fd = Defs
        elif cmd == 'fbin':
            name = line.split()[1]
            DEFINED_WORDS.add(name)
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, '''inline void F_%s() { // %s'
              double a = fs[fp-1];
              double b = fs[fp];
              double z = 0;
              ''' % (nom, name)
            ender = 'fs[--fp] = z; }'
            fd = Defs
        elif cmd == 'fbinw':
            name = line.split()[1]
            DEFINED_WORDS.add(name)
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, '''inline void F_%s() { // %s'
              double b = fs[fp--];
              double a = fs[fp--];
              word z = 0;
              ''' % (nom, name)
            ender = 'ds[++dp] = z; }'
            fd = Defs
        else:
            print >>fd, '        %s' % line
    print >>Defs, ender

    Decls.close()
    Defs.close()


################################################

WHITE = set([' ', '\t', '\n', '\r'])

IS_INT = re.compile(r'^([-]?(0x)?[0-9]+)$').match
IS_HEX = re.compile(r'^([$][0-9a-fA-F]+)$').match
IS_FLOAT = re.compile(r'^[-]?([0-9]+[.][0-9]*|[0-9]*[.][0-9]+)([eE][-]?[0-9]+)$').match
IS_DOUBLE_INT = re.compile(r'^[-]?([0-9]+[.][0-9]*|[0-9]*[.][0-9]+)$').match

SerialNum = 100
def Serial():
    global SerialNum
    SerialNum += 1
    return SerialNum

def Esc(s):
    z = ''
    for ch in s:
        if '0' <= ch <= '9': z += ch
        elif 'A' <= ch <= 'Z': z += ch
        elif 'a' <= ch <= 'z': z += ch
        else:
            z += '_%d_' % ord(ch)
    return z

def CEscape(s):
    z = ''
    for ch in s:
        if '0' <= ch <= '9': z += ch
        elif 'A' <= ch <= 'Z': z += ch
        elif 'a' <= ch <= 'z': z += ch
        else:
            z += '\\%03o' % ord(ch)
    return z

class Lexer(object):
    def __init__(self, program):
        self.program = program
        self.i = 0
        self.n = len(self.program)

    def getChar(self):
        if self.i < self.n:
            ch = self.program[self.i]
            self.i += 1
            return ch
        else:
            return ''

    def mustGetWord(self):
        w = self.getWord().lower()
        assert w
        return w

    def getWordToDefine(self):
        name = self.mustGetWord()
        DEFINED_WORDS.add(name)
        return name, Esc(name)

    def getWord(self):
        # Skip white space.
        while self.i < self.n:
            ch = self.program[self.i]
            if ch not in WHITE: break
            self.i += 1

        # Check for EOF.
        if self.i >= self.n: return ''

        # Find non-white span.
        self.start = self.i
        while self.i < self.n:
            ch = self.program[self.i]
            if ch in WHITE: break
            self.i += 1
        self.limit = self.i

        # Consume the terminating white char.
        if self.i < self.n: self.i += 1

        return self.program[self.start:self.limit]

    def getString(self, termination):
        s = ''
        ch = 'START'
        while ch and ch != termination:
            ch = self.getChar()
            if ch != termination: s += ch
        return s

class Parser(object):
    def __init__(self):
        self.lexer = None
        self.compiling = False
        self.decls = ''
        self.defs = ''
        self.main = ''

    def Parse(self, program):
        self.lexer = Lexer(program)
        self.compiling = False
        while True:
            w = self.lexer.getWord()
            if not w: break
            self.main += '''\nSAY(stderr, "{{{ main calling: `%s`\\n");\n''' % CEscape(w)
            handling = self.HandleWord(w)
            if handling: self.main += handling + ('// <<< %s >>>\n' % w)
            self.main += '''\nSAY(stderr, "     main called: `%s` }}}\\n");\n''' % CEscape(w)
            self.main += '''\nShowStacks();\n'''

    def HandleWord(self, w):
        w = w.lower();
        nom = Esc(w)
        if IS_INT(w):
            return '  push(%sL); // <<< %s >>>' % (w, w)
        elif IS_HEX(w):
            return '  push(0x%s); // <<< %s >>>' % (w[1:], w)
        elif IS_FLOAT(w):
            return '  fpush(%s); // <<< %s >>>' % (w, w)
        elif IS_DOUBLE_INT(w):
            without_dot = w.replace('.', '')
            return '''
                push( (word)(%sLL) ); // low half of double-int <<< %s >>>
                push( (word)(%sLL >> (8*sizeof(word))) ); // high half of double-int <<< %s >>>
                        ''' % (without_dot, w, without_dot, w)
        elif w in DEFINED_WORDS:
            return '      F_%s(); // %s' % (nom, w)
        elif w == '\\': # `\` comments thru end of line
            comment = self.lexer.getString(termination='\n')
            return '// {{{ \\ %s }}}' % repr(comment.strip())

        elif w == '(': # `(` comment thru `)`
            comment = self.lexer.getString(termination=')')
            return '// {{{ ( %s ) }}}' % repr(comment.strip())

        elif w == 's"': # `s"` gets string thru `"`
            s = self.lexer.getString(termination='"')
            k = Serial()
            # self.decls += 'const char S_%d[]; // %s\n' % (k, s)
            self.defs += 'const char S_%d[] = "%s"; // `%s`\n' % (k, CEscape(s), s)

            return 'push((word) &S_%d[0]); push(strlen(S_%d)); // `%s`' % (k, k, s)

        elif w == '."': # `."` prints string thru `"`
            return ' printf("%%s", "%s"); fflush(stdout);' % CEscape(
                    self.lexer.getString(termination='"'))

        elif w == 'create':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                push(V_%s);
            }
            ''' % (nom, name, nom)
            return '''
               SAY(stderr, "=== pre-create here=%%ld\\n", here);
               here = (~7L)&(here+7);
               V_%s = here;
               SAY(stderr, "=== create `%%s` %%ld\\n", "%s", here);
            ''' % (nom, CEscape(name))

        elif w == 'constant':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                push(V_%s);
            }
            ''' % (nom, name, nom)
            return ' V_%s = pop(); // constant %s' % (nom, name)

        elif w == 'variable':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                ds[++dp] = (word)(&V_%s);
               SAY(stderr, "=== get variable `%%s` %%ld\\n", "%s", ds[dp]);
            }
            ''' % (nom, name, nom, name)

        elif w == 'fvariable':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'double V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                ds[++dp] = (word)(&V_%s);
               SAY(stderr, "=== get fvariable `%%s` %%ld\\n", "%s", ds[dp]);
            }
            ''' % (nom, name, nom, name)

        elif w == '2variable':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s[2]; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                ds[++dp] = (word)(&V_%s);
               SAY(stderr, "=== get 2variable `%%s` %%ld\\n", "%s", ds[dp]);
            }
            ''' % (nom, name, nom, name)

        elif w == 'value':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                ds[++dp] = V_%s;
               SAY(stderr, "=== get value `%%s` %%ld\\n", "%s", ds[dp]);
            }
            ''' % (nom, name, nom, name)
            return '''
              V_%s = ds[dp--]; // to %s
              SAY(stderr, "=== init value `%%s` to %%ld\\n", "%s", V_%s);
            ''' % (nom, name, name, nom)

        elif w == 'to':
            name, nom = self.lexer.getWordToDefine()
            return '  V_%s = ds[dp--]; // to %s\n' % (nom, name)

        elif w == 'marker':
            self.lexer.mustGetWord()  # marker name ignored.

        elif w == ":":
            return self.Colon()

        elif w == "begin": return "{ while (1) {"
            
        elif w == "while": return "{ if (!pop()) break; }"
        
        elif w == "repeat": return "} }"
        
        elif w == "do": return '''
            {
              int j = i;
              int start = ds[dp--];
              int limit = ds[dp--];
              for (int i=start; i < limit; i++) {
            '''
        elif w == "loop": return '''
              }
            }
            '''
        elif w == "i": return ' ds[++dp] = i; '
        elif w == "j": return ' ds[++dp] = j; '

        elif w == "if": return '''
                {if (ds[dp--]) {
            '''
        elif w == "else": return '''
                } else {
            '''
        elif w == "then": return '''
                }}
            '''

        else:
            raise Exception('Unknown action: %s' % w)

    def Colon(self):
        name, nom = self.lexer.getWordToDefine()
        body = ''
        self.main += '''\nSAY(stderr, "... compiling `%s`\\n");\n''' % name
        w = self.lexer.mustGetWord()
        while w != ';':
            body += '''\nSAY(stderr, "{{{ calling: `%s`\\n");\n''' % CEscape(w)
            handling = self.HandleWord(w)
            if handling: body += handling + ('// <<< %s >>>\n' % w)
            body += '''\nSAY(stderr, "     called: `%s` }}}\\n");\n''' % CEscape(w)
            body += '''\nShowStacks();\n'''
            w = self.lexer.mustGetWord()

        self.decls += '''void F_%s(); // %s''' % (nom, name)
        self.defs += '''inline void F_%s() { // %s
int i=0, j=0;
%s
        }
        ''' % (nom, name, body)

CompilePrims(PRIM_DEFINITIONS)
parser = Parser()
for filename in sys.argv[1:]:
    parser.Parse(open(filename).read())

print '''
// VM_HEADER
%s
// DECLARATIONS
// parser.decls
%s
// str(Decls)
%s

// DEFINITIONS
// parser.defs
%s
// str(Defs)
%s

// MAIN
int main(int argc, const char* argv[]) {
  assert(sizeof(short) == 2);
  VMInitialize();
  int i=0, j=0;

  // parser.main
  %s
}
// END
''' % (VM_HEADER, parser.decls, str(Decls), parser.defs, str(Defs), parser.main)

pass
