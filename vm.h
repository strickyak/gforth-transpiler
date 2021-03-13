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

inline word B(word x) { return x? -1 : 0; }

inline void push(word a) { ds[++dp] = a; }
inline word pop() { return ds[dp--]; }
inline void pushb(word a) { ds[++dp] = B(a); }

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
}
