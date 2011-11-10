#!/usr/bin/env python
import sys

if not len(sys.argv)==2:
    raise "expected HIGH_SCORE_BIGRAMS"
high_score_bigrams_file = sys.argv[1:][0]

bigrams = set()
for bigram in open(high_score_bigrams_file,'r'):
    bigrams.add(tuple(bigram.strip().split("\t")))

for line in sys.stdin:
    tokens = line.strip().split()
    if len(tokens)<2:
        continue

    t1 = tokens.pop(0)
    while len(tokens)>0:
        t2 = tokens.pop(0)
        bigram = (t1,t2)
        if bigram in bigrams:
            sys.stdout.write("("+t1+"_"+t2+") ")
            if len(tokens)>0:
                t1 = tokens.pop(0)
            else:
                t1 = None
        else:
            sys.stdout.write(t1+" ")
            t1 = t2
    if t1:
        sys.stdout.write(t1)
    sys.stdout.write("\n")

