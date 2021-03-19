\ test1.4th

  100 2 + 102 = must ~
  100 2 - 98 = must ~
  2 100 - -98 = must ~
  100 2 * 200 = must ~
  99 5 mod 4 = must ~

  : double  ( a b - sum )  dup +  ;
  444 double 888 = must

  333. 555.0 f+ 888.0 f= must ~
  333. 555.0 f- -222.0 f= must ~
  555.0 333. f- 222.0 f= must ~
  10. 200.0 f* 2000. f= must ~
  16. fdup f* 256. f= must ~

  0 s>f 0. f= must ~
  42 s>f 42. f= must ~

12345 negate -12345 = must ~
-12345 negate 12345 = must ~
0 negate 0 = must ~

1234.5 fnegate -1234.5 f= must ~
-1234.5 fnegate 1234.5 f= must ~
0. fnegate 0. f= must ~

1 cells 4 = if
  42 0 d>f  fdup f.   42.         f= must ~
  0 1 d>f   fdup f.   4294967296. f= must ~
  42 1 d>f  fdup f.   4294967338. f= must ~
  42 2 d>f  fdup f.   8589934634. f= must ~
then

1 cells 8 = if
  42 0 d>f  fdup f.   42. f= must ~
  0 1 d>f   fdup f.   0.  f= must ~
  42 1 d>f  fdup f.   42. f= must ~
  42 2 d>f  fdup f.   42. f= must ~
then

-4 3 mod 2 = must ~
-3 3 mod 0 = must ~
-2 3 mod 1 = must ~
-1 3 mod 2 = must ~
0 3 mod 0 = must ~
1 3 mod 1 = must ~
2 3 mod 2 = must ~
3 3 mod 0 = must ~
4 3 mod 1 = must ~
5 3 mod 2 = must ~
6 3 mod 0 = must ~
7 3 mod 1 = must ~

variable a
variable b
variable c
30 a ! 2 b !  a @ b @ + c !  c @ 32 = must
              a @ b @ * c !  c @ 60 = must ~

404 value not_found
1 not_found 2 ( ) 2 = must 404 = must 1 = must ~
400 to not_found
1 not_found 2 ( ) 2 = must 400 = must 1 = must ~

2variable 2foo
22 33 2foo 1 cells + ! 2foo !
2foo 1 cells + @ 2foo @ + 55 = must ~

10 0 do i 1+ . loop  cr ~
11 1 do i dup * . loop  cr ~
10 0 do i 2 mod 0= if i . then loop  cr ~
10 0 do i 2 mod if i dup * . else i . then loop  cr ~

  ." . . .
Excellent ! ! !" cr ( comment )
