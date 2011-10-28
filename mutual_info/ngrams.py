#!/usr/bin/env python
import sys
if not len(sys.argv)==2:
    raise "expected NGRAM_LENGTH"
ngram_len = int(sys.argv[1])
   
for line in sys.stdin:
    tokens = line.strip().split()
    if ngram_len == 1:
        for token in tokens:
            print token
    else:
        if len(tokens) < ngram_len: continue
        for i in range(0,len(tokens)-ngram_len+1):
            print "\t".join(tokens[i:i+ngram_len])
