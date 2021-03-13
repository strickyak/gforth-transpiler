import re, sys

WHITE = set([' ', '\t', '\n', '\r'])

DEFINED_WORDS = set([w.rstrip() for w in open('_words.tmp')])

IS_INT = re.compile('^([-]?(0x)?[0-9]+)$').match
IS_HEX = re.compile('^([$][0-9a-fA-F]+)$').match
IS_FLOAT = re.compile('^[-]?([0-9]+[.][0-9]*|[0-9]*[.][0-9]+)([eE][-]?[0-9]*)?$').match
IS_CLEAN = re.compile('''^[^\\\\'"]*$''').match

SerialNum = 100
def Serial():
    global SerialNum
    SerialNum += 1
    return SerialNum

def Esc(s):
    z = ''
    for ch in s:
        if '0' <= ch <= '9': z += ch
        elif 'A' <= ch <= 'Z': z += ch
        elif 'a' <= ch <= 'z': z += ch
        else:
            z += '_%d_' % ord(ch)
    return z

def CEscape(s):
    z = ''
    for ch in s:
        if '0' <= ch <= '9': z += ch
        elif 'A' <= ch <= 'Z': z += ch
        elif 'a' <= ch <= 'z': z += ch
        else:
            z += '\\%03o' % ord(ch)
    return z

class Lexer(object):
    def __init__(self, program):
        self.program = program
        self.i = 0
        self.n = len(self.program)

    def getChar(self):
        if self.i < self.n:
            ch = self.program[self.i]
            self.i += 1
            return ch
        else:
            return ''

    def mustGetWord(self):
        w = self.getWord().lower()
        assert w
        return w

    def getWordToDefine(self):
        name = self.mustGetWord()
        DEFINED_WORDS.add(name)
        return name, Esc(name)

    def getWord(self):
        # Skip white space.
        while self.i < self.n:
            ch = self.program[self.i]
            if ch not in WHITE: break
            self.i += 1

        # Check for EOF.
        if self.i >= self.n: return ''

        # Find non-white span.
        self.start = self.i
        while self.i < self.n:
            ch = self.program[self.i]
            if ch in WHITE: break
            self.i += 1
        self.limit = self.i

        # Consume the terminating white char.
        if self.i < self.n: self.i += 1

        return self.program[self.start:self.limit]

    def getString(self, termination):
        s = ''
        ch = 'START'
        while ch and ch != termination:
            ch = self.getChar()
            if ch != termination: s += ch
        return s

class Parser(object):
    def __init__(self):
        self.lexer = None
        self.compiling = False
        self.decls = ''
        self.defs = ''
        self.inits = ''
        self.main = ''

    def Parse(self, program):
        self.lexer = Lexer(program)
        self.compiling = False
        while True:
            w = self.lexer.getWord()
            if not w: break
            self.main += '''\nSAY(stderr, "{{{ main calling: `%s`\\n");\n''' % CEscape(w)
            handling = self.HandleWord(w)
            if handling: self.main += handling + ('// <<< %s >>>\n' % w)
            self.main += '''\nSAY(stderr, "     main called: `%s` }}}\\n");\n''' % CEscape(w)
            self.main += '''\nShowStacks();\n'''

    def HandleWord(self, w):
        w = w.lower();
        nom = Esc(w)
        if IS_INT(w):
            return '  push(%sL); // <<< %s >>>' % (w, w)
        elif IS_HEX(w):
            return '  fpush(0x%s); // <<< %s >>>' % (w[1:], w)
        elif IS_FLOAT(w):
            return '  fpush(%s); // <<< %s >>>' % (w, w)
        elif w in DEFINED_WORDS:
            return '      F_%s(); // %s' % (nom, w)
        elif w == '\\': # `\` comments thru end of line
            comment = self.lexer.getString(termination='\n')
            return '// {{{ \\ %s }}}' % repr(comment.strip())

        elif w == '(': # `(` comment thru `)`
            comment = self.lexer.getString(termination=')')
            return '// {{{ ( %s ) }}}' % repr(comment.strip())

        elif w == 's"': # `s"` gets string thru `"`
            s = self.lexer.getString(termination='"')
            k = Serial()
            # self.decls += 'const char S_%d[]; // %s\n' % (k, s)
            self.defs += 'const char S_%d[] = "%s"; // `%s`\n' % (k, CEscape(s), s)

            return 'push((word) &S_%d[0]); push(strlen(S_%d)); // `%s`' % (k, k, s)

        elif w == '."': # `."` prints string thru `"`
            return ' printf("%%s", "%s"); fflush(stdout);' % CEscape(
                    self.lexer.getString(termination='"'))

        elif w == 'create':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                push(V_%s);
            }
            ''' % (nom, name, nom)
            return '''
               SAY(stderr, "=== pre-create here=%%ld\\n", here);
               here = (~7L)&(here+7);
               V_%s = here; 
               SAY(stderr, "=== create `%%s` %%ld\\n", "%s", here);
            ''' % (nom, CEscape(name)) 

        elif w == 'constant':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                push(V_%s);
            }
            ''' % (nom, name, nom)
            return ' V_%s = pop(); // constant %s' % (nom, name)

        elif w == 'variable':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                ds[++dp] = (word)(&V_%s);
               SAY(stderr, "=== get variable `%%s` %%ld\\n", "%s", ds[dp]);
            }
            ''' % (nom, name, nom, name)

        elif w == 'fvariable':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'double V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                ds[++dp] = (word)(&V_%s);
               SAY(stderr, "=== get fvariable `%%s` %%ld\\n", "%s", ds[dp]);
            }
            ''' % (nom, name, nom, name)

        elif w == '2variable':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s[2]; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                ds[++dp] = (word)(&V_%s);
               SAY(stderr, "=== get 2variable `%%s` %%ld\\n", "%s", ds[dp]);
            }
            ''' % (nom, name, nom, name)

        elif w == 'value':
            name, nom = self.lexer.getWordToDefine()
            self.defs += 'word V_%s; // %s\n' % (nom, name)
            self.decls += '''void F_%s(); // %s\n''' % (nom, name)
            self.defs += '''void F_%s() { // %s
                ds[++dp] = V_%s;
               SAY(stderr, "=== get value `%%s` %%ld\\n", "%s", ds[dp]);
            }
            ''' % (nom, name, nom, name)
            return '''
              V_%s = ds[dp--]; // to %s
              SAY(stderr, "=== init value `%%s` to %%ld\\n", "%s", V_%s);
            ''' % (nom, name, name, nom)

        elif w == 'to':
            name, nom = self.lexer.getWordToDefine()
            return '  V_%s = ds[dp--]; // to %s\n' % (nom, name)

        elif w == 'marker':
            self.lexer.mustGetWord()  # marker name ignored.

        elif w == ":":
            return self.Colon()

        elif w == "xxx do": return '''
              rp += 2;
              rs[rp] = ds[dp--];  // i
              rs[rp-1] = ds[dp--];  // limit
              while (rs[rp] < rs[rp-1]) {
            '''
        elif w == "xxx loop": return '''
                rs[rp]++;
              }
              rp-=2;
            '''

        elif w == "do": return '''
            {
              int j = i;
              int start = ds[dp--];
              int limit = ds[dp--];
              for (int i=start; i < limit; i++) {
            '''
        elif w == "loop": return '''
              }
            }
            '''
        elif w == "i": return ' ds[++dp] = i; '
        elif w == "j": return ' ds[++dp] = j; '

        elif w == "if": return '''
                {if (ds[dp--]) {
            '''
        elif w == "else": return '''
                } else {
            '''
        elif w == "then": return '''
                }}
            '''

        else:
            raise Exception('Unknown action: %s' % w)

    def Colon(self):
        name, nom = self.lexer.getWordToDefine()
        body = ''
        self.main += '''\nSAY(stderr, "... compiling `%s`\\n");\n''' % name
        w = self.lexer.mustGetWord()
        while w != ';':
            body += '''\nSAY(stderr, "{{{ calling: `%s`\\n");\n''' % CEscape(w)
            handling = self.HandleWord(w)
            if handling: body += handling + ('// <<< %s >>>\n' % w)
            body += '''\nSAY(stderr, "     called: `%s` }}}\\n");\n''' % CEscape(w)
            body += '''\nShowStacks();\n'''
            w = self.lexer.mustGetWord()

        self.decls += '''void F_%s(); // %s''' % (nom, name)
        self.defs += '''inline void F_%s() { // %s
int i=0, j=0;
%s
        }
        ''' % (nom, name, body)

parser = Parser()
parser.Parse(open('_colons.tmp').read())
for filename in sys.argv[1:]:
    parser.Parse(open(filename).read())

print '''
#include "vm.h"
// DECLARATIONS
%s
#include "_defs.h"

// DEFINITIONS
%s
#include "_decls.h"

// INITIALIZATIONS
void Initialize() {
%s
}

// MAIN
int main(int argc, const char* argv[]) {
  VMInitialize();
  Initialize();
  int i=0, j=0;
%s
}
// END
''' % (parser.decls, parser.defs, parser.inits, parser.main)

pass
