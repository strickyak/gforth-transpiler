import pile

assert (pile.ParseSignature('( a a2 - b b2 | c - d )'.split())
        == (['a', 'a2'], ['b', 'b2'], ['c'], ['d']))

assert (pile.ParseSignature('( - )'.split())
        == ([], [], [], []))
