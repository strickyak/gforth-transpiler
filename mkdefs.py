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

Decls = open('decls.h', 'w')
Defs = open('defs.h', 'w')
Words = open('words.tmp', 'w')
Colons = open('colons.tmp', 'w')
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
Words.close()
