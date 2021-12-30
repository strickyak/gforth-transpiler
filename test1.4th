\ test1.4th

: must-be-near
  f3dup f+ f<= must
        f- f>= must
  ;

: fcells   8 * ;

\ Using fconvolve ( post_incr_ptr pre_decr_ptr n -- | -- result ):
\ Compute (111*9 + 222*8 + 333*7) => 5106, with fconvolve.
\ fconvolve takes two pointers to 8-byte floating point arrays
\ and the number of terms to add.
\ The first pointer is post-incremented for each term.
\ The second pointer is pre-decremented for each term.
\ The floating point result is left on the floating stack.
create forward  3 fcells allot
create backward  3 fcells allot

forward
  dup 111.0e0 f!      1 fcells +
  dup 222.0e0 f!      1 fcells +
  dup 333.0e0 f!      drop

backward
  dup 7.0e0 f!      1 fcells +
  dup 8.0e0 f!      1 fcells +
  dup 9.0e0 f!      1 fcells +   \ keep end-of-backward on stack

forward swap 3 fconvolve      5106.0e0 f= must ~


0.0e0 fsin fdup f.   0.0e0                   f= must ~
1.0e0 fsin fdup f.   0.841470984807897e0     1.0e-15 must-be-near ~
3.14e0 fsin fdup f.  0.00159265291648683e0   1.0e-15 must-be-near ~

0.0e0 fcos fdup f.    1.0e0                  f= must ~
1.0e0 fcos fdup f.    0.54030230586814e0     1.0e-15 must-be-near ~
3.14e0 fcos fdup f.  -0.999998731727539e0    1.0e-15 must-be-near ~


cr
." ((( "
    : fpi 3.14159265358979e0 ;
    : fsqrt2 1.414213562373095e0 ;
    ." pi=" fpi f.
    ." sin(pi/4)=" fpi 4.0e0 f/ fsin fdup f.  fdup f+  fsqrt2 1.0e-15 must-be-near ~
." ))) "
cr

7 s>d d0> must ~
-7 s>d d0> 0= must ~
0 s>d d0> 0= must ~
-12345 s>d d>s -12345 = must ~
12345 s>d d>s 12345 = must ~
12345 67890 d>s 12345 = must ~
-12345 67890 d>s -12345 = must ~
12345678 s>d d>f f>d d>s 12345678 = must ~
12345671234567.0e0 f>d d>f 12345671234567.0e0 f= must ~

  100 2 + 102 = must ~
  100 2 - 98 = must ~
  2 100 - -98 = must ~
  100 2 * 200 = must ~
  99 5 mod 4 = must ~

  : double  ( a b - sum )  dup +  ;
  444 double 888 = must

  333.e0 555.0e0 f+ 888.0e0 f= must ~
  333.e0 555.0e0 f- -222.0e0 f= must ~
  555.0e0 333.e0 f- 222.0e0 f= must ~
  10.e0 200.0e0 f* 2000.e0 f= must ~
  16.e0 fdup f* 256.e0 f= must ~

  0 s>f 0.e0 f= must ~
  42 s>f 42.e0 f= must ~

\ double-int

  123456.    0 = must 123456 = must ~
  123.456    0 = must 123456 = must ~
  .123456    0 = must 123456 = must ~

  123456789123456789.
  1 cells 4 = if
      28744523 = must   -1395630315 = must
  else
      0 = must   123456789123456789 = must
  then ~

  123456789123456789. d>f
    123456789123456789.0e0 f= must ~
\

12345 negate -12345 = must ~
-12345 negate 12345 = must ~
0 negate 0 = must ~

1234.5e0 fnegate -1234.5e0 f= must ~
-1234.5e0 fnegate 1234.5e0 f= must ~
0.e0 fnegate 0.e0 f= must ~

3 80 6 */ 40 = must ~
300000 8000000 600000 */ 4000000 = must ~

s" 12345678" 8 = must
8 0 do dup i +     c@ . loop
4 0 do dup i 2 * + w@ . loop
dup w@ 12849 = if ." (Intel Order) " else ." (Not Intel Order) " then
drop ~

create foo 8 allot

\ This is for signed "sw@".
0 foo w! foo sw@ 0 = must ~
42 foo w! foo sw@ 42 = must ~
-42 foo w! foo sw@ -42 = must ~
-32768 foo w! foo sw@ -32768 = must ~
32768 foo w! foo sw@ -32768 = must ~
32767 foo w! foo sw@ 32767 = must ~
32769 foo w! foo sw@ -32767 = must ~

\ This is for unsigned "uw@".
0 foo w! foo uw@ 0 = must ~
42 foo w! foo uw@ 42 = must ~
-1 foo w! foo uw@ -1 65536 + = must ~
-2 foo w! foo uw@ -2 65536 + = must ~
-42 foo w! foo uw@ -42 65536 + = must ~
32767 foo w! foo uw@ 32767 = must ~
32768 foo w! foo uw@ 32768 = must ~
32769 foo w! foo uw@ 32769 = must ~

\ This is for unsigned "w@".
0 foo w! foo uw@ 0 = must ~
42 foo w! foo uw@ 42 = must ~
-1 foo w! foo uw@ -1 65536 + = must ~
-2 foo w! foo uw@ -2 65536 + = must ~
-42 foo w! foo uw@ -42 65536 + = must ~
32767 foo w! foo uw@ 32767 = must ~
32768 foo w! foo uw@ 32768 = must ~
32769 foo w! foo uw@ 32769 = must ~


1 cells 4 = if
  42 0 d>f  fdup f.   42.e0         f= must ~
  0 1 d>f   fdup f.   4294967296.e0 f= must ~
  42 1 d>f  fdup f.   4294967338.e0 f= must ~
  42 2 d>f  fdup f.   8589934634.e0 f= must ~
then

1 cells 8 = if
  42 0 d>f  fdup f.   42.e0 f= must ~
  0 1 d>f   fdup f.   0.e0  f= must ~
  42 1 d>f  fdup f.   42.e0 f= must ~
  42 2 d>f  fdup f.   42.e0 f= must ~
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


\ Test of BEGIN, WHILE, REPEAT.
\ Check 5050 == 1 + 2 + 3 + ... + 100
0 a !   0 b !   0 c !
begin
  \ LET c = a + c
  a @ c @ + c !

  \ WHILE (a < 100)
  a @ 100 < while

  \ LET a = a + 1
  a @ 1+ a !
repeat
  a @ 100 = must ~
  c @ 5050 = must ~


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
