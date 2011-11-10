#!/usr/bin/env python
import sys, re
for line in sys.stdin:
    m = re.match('\s*(\d*) (.*)',line.strip())
    if not m:
        print "wtf?",line
        continue
    freq, term = m.groups()
    num_underscores = term.count('_')
    print "\t".join(map(str, [freq, term, num_underscores]))
