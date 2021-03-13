1 constant BENCH
4 constant VLEN
VLEN dup * constant MLEN

fvariable side_effect

8 constant 1fcells
: fcells 1fcells * ;

: vector_sum ( fp -- ; -- fsum )
  0 s>f
  VLEN 0 DO
    dup i fcells + f@ f+
  LOOP
  drop
  ;

fvariable ftmp2
: vector_dot_product ( fp gp -- ; -- fdotprod )
  0 s>f
  VLEN 0 DO
    dup i fcells + f@
    over i fcells + f@
    f* f+
  LOOP
  drop drop
  ;


variable tmp_out_vp
: matrix_mul_vector ( mp vp out_vp -- )
  tmp_out_vp !
                ( vp0 mp0 | )
  dup -rot
                ( vp0 mp0 vp0 | )
  VLEN 0 DO
    0 s>f       ( vp0 mp0 vp0 | 0.0 )
    VLEN 0 DO
      dup f@ ( vp0 mp vp | vp[i] )
      1fcells +
                                 ( vp0 mp vp++ |  *vp  )
      swap dup f@
           1fcells + swap
                                 ( vp0 mp++ vp++ |  {*vp} * {*mp} )
      f* f+
                                 ( vp0 mp++ vp++ | sum_of_products )
    LOOP
    drop over
                         ( vp0 mp vp0 | sum_of_products )
    tmp_out_vp @ f!
                         ( vp0 mp vp0 | )
    tmp_out_vp @ 1fcells + tmp_out_vp !
  LOOP
  drop drop drop ;

: set_identity_matrix ( mp - )
  VLEN 0 DO
    VLEN 0 DO
      i j =  IF 1 ELSE 0 THEN s>f
      dup f!
      1fcells +
    LOOP
  LOOP
  drop ;

: set_small_transform_matrix ( mp - )
  VLEN 0 DO
    VLEN 0 DO
      i j = IF
          1 s>f j s>f 1000 s>f f/ f+
        ELSE
          0 s>f j s>f 2000 s>f f/ f- i s>f 1000 s>f f/ f+
        THEN
      dup f!
      1fcells +
    LOOP
  LOOP
  drop ;

: print_vec ( vp - )
  cr
  VLEN 0 DO
    dup f@ f.
    1fcells +
  LOOP
  drop cr ;

: print_mat ( mp - )
  cr
  VLEN 0 DO
    VLEN 0 DO
      dup f@ f.
      1fcells +
    LOOP
    cr
  LOOP
  drop cr ;

create vec1 VLEN fcells allot
create vec2 VLEN fcells allot
create mat1 MLEN fcells allot
create transform MLEN fcells allot
: run-once

  VLEN 0 DO
    i 1 +   s>f
      vec1 i fcells + f!
  LOOP
  BENCH if else  vec1 print_vec  then

  mat1 set_identity_matrix
  BENCH if else  mat1 print_mat  then

  transform set_small_transform_matrix
  BENCH if else  transform print_mat  then

  100 2 /  0  DO
    transform vec1 vec2  matrix_mul_vector
    transform vec2 vec1  matrix_mul_vector
  LOOP

  BENCH if else  
    vec1 print_vec
    vec2 print_vec
  then
  ;

: main
  0 s>f side_effect f!
  1000000 0 DO
    run-once
    vec1 vector_sum   side_effect f@ f+ side_effect f!    
  LOOP
  ." side_effect=" side_effect f@ f. cr
  ;

main bye
