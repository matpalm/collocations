#!/usr/bin/env python
import sys
for line in sys.stdin:
    tokens = line.split()
    while len(tokens)!=0:
        next = tokens.pop(0)
        d = 1
        for other in tokens:
            print "\t".join([next,other,str(d)])
            print "\t".join([other,next,str(-d)])
            d += 1
