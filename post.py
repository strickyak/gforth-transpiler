# Filter to normalize how floating point numbers are printed
# to clean up diffs between gforth and transpiler output.
#
#   python post.py < output > normalized_output

import re, sys

SEARCH_FLOAT = re.compile(r'([-]?([0-9]+[.][0-9]*|[0-9]*[.][0-9]+)([eE][-]?[0-9]+)?)(.*)$').search

for line in sys.stdin:
	done, rest = '', line.rstrip()
	while rest:
		m = SEARCH_FLOAT(rest)
		if not m:
			done += rest
			break
        	start, end = m.start(1), m.end(1)

        	front, middle, back = rest[:start], rest[start:end], rest[end:]

        	done += front + ('%.15g' % float(m.group(1)))
		rest = back
		# print 'TRANFORM', m.group(1), ('%.15g' % float(m.group(1)))
	print( done )
