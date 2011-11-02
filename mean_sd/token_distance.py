#!/usr/bin/env python
import sys
for line in sys.stdin:
    tokens = line.split()
    # for each token in the sentence split
    while len(tokens)!=0:
        next = tokens.pop(0)
        d = 1
        # emit that token and the next 9, with a distance (both ways)
        for other in tokens[0:9]:
            print "\t".join([next,other,str(d)])
            print "\t".join([other,next,str(-d)])
            d += 1
