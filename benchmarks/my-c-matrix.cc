#include <cstdio>

constexpr int VLEN = 4;
constexpr int MLEN = VLEN * VLEN;

using Int = int;
using Float = double;

Float side_effect;

Float vector_sum(Float* fp) {
  Float z = 0.0;
  for (Int i = 0; i < VLEN; i++) z += *fp++;
  return z;
}

Float vector_sum_n(Float* fp, Int n) {
  Float z = 0.0;
  for (Int i = 0; i < n; i++) z += *fp++;
  return z;
}

Float vector_dot_product(Float* fp, Float* gp) {
  Float z = 0.0;
  for (Int i = 0; i < VLEN; i++) z += *fp++ * *gp++;
  return z;
}

Float vector_dot_product_n(Float* fp, Float* gp, Int n) {
  Float z = 0.0;
  for (Int i = 0; i < n; i++) z += *fp++ * *gp++;
  return z;
}

void matrix_mul_vector(Float* mp, Float* vp, Float* out_vp) {
  for (Int row = 0; row < VLEN; row++) {
    out_vp[row] = 0.0;
    for (Int col = 0; col < VLEN; col++) {
      out_vp[row] += *mp++ * vp[col];
    }
  }
}

void set_identity_matrix(Float* out_mp) {
  for (Int row = 0; row < VLEN; row++) {
    for (Int col = 0; col < VLEN; col++) {
      *out_mp++ = (row==col) ? 1.0 : 0.0;
    }
  }
}

void set_small_transform_matrix(Float* out_mp) {
  for (Int row = 0; row < VLEN; row++) {
    for (Int col = 0; col < VLEN; col++) {
      *out_mp++ = (row==col) ? 1.0 + (row/1000.0) : 0.0 - (row/2000.0) + (col/1000.0);
    }
  }
}

void print_vec(Float* vp) {
  for (Int i = 0; i < VLEN; i++) {
    printf("%16g ", *vp++);
  }
  printf("\n\n");
}

void print_mat(Float* mp) {
  for (Int row = 0; row < VLEN; row++) {
    for (Int col = 0; col < VLEN; col++) {
      printf("%16g ", *mp++);
    }
    printf("\n");
  }
  printf("\n");
}

void run_once() {
  Float vec1[VLEN] = {1.0, 2.0, 3.0, 4.0};

  Float mat1[MLEN];
  set_identity_matrix(mat1);

  Float transform[MLEN];
  set_small_transform_matrix(transform);

#ifndef BENCH
  print_vec(vec1);
  print_mat(mat1);
  print_mat(transform);
#endif

  Float vec2[VLEN];
  for (Int i=0; i<100/2; i++) {
     matrix_mul_vector(transform, vec1, vec2);
     matrix_mul_vector(transform, vec2, vec1);
  }
#ifndef BENCH
  print_vec(vec1);
  print_vec(vec2);

  printf("%16g (dot product)\n", vector_dot_product(vec1, vec2));
  printf("%16g (sum vec1)\n", vector_sum(vec1));
  printf("%16g (sum vec2)\n", vector_sum(vec2));
#endif
  side_effect += vector_sum(vec1);
}

int main() {
  for (int i = 0; i < 1000000; i++) {
    run_once();
  }
  printf("side_effect=%g\n", side_effect);
}
