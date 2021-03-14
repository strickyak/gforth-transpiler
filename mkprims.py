# This program compiles the definitions in "prims.txt".
# to produce four intermediate files:
#
#   _decls.h    -- declarations of C++ stuff.
#   _defs.h     -- inline definitions of c++ stuff.
#   _words.tmp  -- a list of words defined in prims.txt, one per line.
#   _colons.tmp -- colon definitions from prims.txt.
#
# The first two will be included by the C++ compiler.
# The latter two will be read by pile.py.

import sys

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

def main():
    Decls = open('_decls.h', 'w')
    Defs = open('_defs.h', 'w')
    Words = open('_words.tmp', 'w')
    Colons = open('_colons.tmp', 'w')
    fd = Defs

    ender = ''
    for line in sys.stdin:
        line = line.rstrip()
        cmd = line.split()[0] if line.split() else '**empty**'
        if line.startswith('#'):
            pass
        elif cmd ==('def'):
            name = line.split()[1]
            print >>Words, name
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, 'inline void F_%s() { // %s' % (nom, name)
            ender = '}'
            fd = Defs
            sig = ParseSignature(line.split()[2:])
        elif cmd ==('bin'):
            name = line.split()[1]
            print >>Words, name
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
        elif cmd ==('un'):
            name = line.split()[1]
            print >>Words, name
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, '''inline void F_%s() { // %s'
              word a = ds[dp];
              word z = 0;
              ''' % (nom, name)
            ender = 'ds[dp] = z; }'
            fd = Defs
        elif cmd ==('fun'):
            name = line.split()[1]
            print >>Words, name
            nom = Esc(name)
            print >>Decls, 'void F_%s(); // %s' % (nom, name)
            print >>Defs, ender
            print >>Defs, '''inline void F_%s() { // %s'
              double a = fs[fp];
              double z = 0;
              ''' % (nom, name)
            ender = 'fs[fp] = z; }'
            fd = Defs
        elif cmd ==('fbin'):
            name = line.split()[1]
            print >>Words, name
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
        elif cmd ==('fbinw'):
            name = line.split()[1]
            print >>Words, name
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
        elif cmd ==(':'):
            print >>Colons, line
            fd = Colons
        else:
            print >>fd, '        %s' % line
    print >>Defs, ender

    Decls.close()
    Defs.close()
    Words.close()
    Colons.close()

if __name__ == '__main__':
    main()
