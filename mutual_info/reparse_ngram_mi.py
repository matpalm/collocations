#!/usr/bin/env python
import sys
for line in sys.stdin:
    cols = line.strip().split("\t")
    mi, freq = cols.pop(), cols.pop()
    ngram = " ".join(cols)
    print "\t".join([ngram, freq, mi])
