#!/usr/bin/env python
import sys
for line in sys.stdin:
    tokens = line.strip().split()
    if len(tokens) < 2: continue
    while len(tokens) > 0:
        next = tokens.pop(0)
        for other in tokens[0:3]: # max two tokens between
            print next + "\t" + other
    #for i in range(0,len(tokens)-ngram_len+1):
    #    print "\t".join(tokens[i:i+ngram_len])
