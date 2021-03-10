#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include <cassert>
#include <cmath>
#include <ctgmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>

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
  fprintf(stderr, "sizeof (int) = %d\n", sizeof(int));
  fprintf(stderr, "sizeof (word) = %d\n", sizeof(word));
  fprintf(stderr, "sizeof (uword) = %d\n", sizeof(uword));
  fprintf(stderr, "sizeof (long) = %d\n", sizeof(long));
  fprintf(stderr, "sizeof (char*) = %d\n", sizeof(char*));
  fprintf(stderr, "sizeof (word*) = %d\n", sizeof(word*));

  here = (word)(&heap[0]);
  fprintf(stderr, "=== here = %ld\n", here);
}

void ShowStacks() {
  fprintf(stderr, "\t\t\t[[[ ");
  for (word i=1; i<=dp; i++) fprintf(stderr, "%ld ", ds[i]);
  fprintf(stderr, ";;; ");
  for (word i=1; i<=rp; i++) fprintf(stderr, "0x%lx ", rs[i]);
  fprintf(stderr, ";;; ");
  for (word i=1; i<=fp; i++) fprintf(stderr, "%.12g ", fs[i]);
  fprintf(stderr, "]]] ...... %d %d %d\n", dp, rp, fp);
  assert(dp >= 0);
  assert(rp >= 0);
  assert(fp >= 0);
  assert(dp < 100);
  assert(rp < 100);
  assert(fp < 100);
}
