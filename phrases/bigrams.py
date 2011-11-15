#!/usr/bin/env python
import sys
for line in sys.stdin:
    tokens = line.strip().split()
    if len(tokens)<2: continue
    t1 = tokens.pop(0)
    while len(tokens)>0:
        t2 = tokens.pop(0)
        print t1, t2
        t1 = t2


        
