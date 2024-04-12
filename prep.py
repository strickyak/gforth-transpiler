# Filter to make gforth code more verbose.
#
#  python2 prep.py < program.4th > modified.4th
#
# Serving Suggetion:
#
# Here's a script that preprocesses, runs, and postprocesses
# with the original program in p.4th
"""
python2 prep.py < p.4th > q.4th && echo 0437Taps | gforth-fast q.4th | head -5000 > ,1
python2 prep.py < p.4th > q.4th && echo 0437Taps | gforth-fast q.4th | head -5000 > ,2
diff ,1 ,2 | wc

python2 pile.py  q.4th > q.cc
clang-format-3.9 q.cc > qq.cc
g++ -std=c++11 -g -o q qq.cc -lm
echo 0437Taps | ./q | head -5000 > ,3
diff ,1 ,3 | wc

python post.py < ,1 > ,11
python post.py < ,2 > ,22
python post.py < ,3 > ,33
diff ,11 ,33 | wc
"""

import re, sys

F_REMARK = re.compile(r'^[ \t]*\\', re.S).match
BRACED = re.compile(r'\b({.*?})\b(.*)', re.S).search

def TweakWith(s, searcher, num_middles, format):
    done, rest = '', s
    while rest:
        #print '\\ CONSIDER: %s' % rest
	m = BRACED(rest)
	if m:
        	start, end = m.start(1), m.end(1)
        	front, middle, back = rest[:start], rest[start:end], rest[end:]
        	done += front + middle
        	rest = back
		continue
        m = searcher(rest)
        if not m:
            #print '\\ NO MATCH'
            done += rest
            break
        #print '\\ GROUPS: %s' % list(m.groups())
        start, end = m.start(1), m.end(1)
        #print '\\ START=%d end=%d' % (start, end)
        front, middle, back = rest[:start], rest[start:end], rest[end:]
        #print '\\ FRONT[%s] MIDDLE[%s] BACK[%s]' % (front, middle, back)
        done += front + format % tuple(num_middles * [middle])
        rest = back
    return done

DGreaterF = re.compile(r'\b(d>f)\b(.*)').search
def TweakDGreaterF(s):
	return TweakWith(s, DGreaterF, 3, '''
                               cr ."  { EXECUTING %s } "
            swap dup .  
                               ."  { %s } "
            swap dup .
                               ."  { ==> } "
            %s fdup f.
                               ."  { } " cr
	''')

F_BINARY = re.compile(r'\b(f[*][*]|f[-+*/]|fmod)(.*)$', re.S).search
def TweakFBinary(s):
	return TweakWith(s, F_BINARY, 3, '''
                               cr ."  { EXECUTING F_BINARY %s } "
            fswap fdup f.  
                               ."  {  %s } "
            fswap fdup f.
                               ."  {==> } "
            %s fdup f.
                               ."  { } " cr
	''')

def TweakAll(s):
	for fn in [TweakDGreaterF, TweakFBinary]:
		#print 'BEFORE:', fn, s
		s = fn(s)
		#print 'AFTER:', fn, s
	return s

for line in sys.stdin:
    if F_REMARK(line):
        print( line.strip() + ' \\  REMARK' )
    else:
        print( '\\ <<<<<' )
        print( TweakAll(line.rstrip()) )
        print( '\\ >>>>>' )
