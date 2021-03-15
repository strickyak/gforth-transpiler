1000000 constant #ROUNDS
1000 constant SIZE
: fcells 8 * ;

fvariable bogus
create v1  SIZE fcells allot
create v2  SIZE fcells allot

: init
  SIZE 0 do
    i s>f   v1  i 8 * +  f!
    i 2 + s>f   v2  i 8 * +  f!
  loop ;

: vector_dot_product ( fp gp size -- ; -- fdotprod )
  0 s>f
  0 DO
    dup i fcells + f@
    over i fcells + f@
    f* f+
  LOOP
  drop drop ;

: main
  init
  0 s>f
  #ROUNDS 0 do
    v1 v2 SIZE vector_dot_product f+
  loop
  ." answer=" f. cr ;

main bye
