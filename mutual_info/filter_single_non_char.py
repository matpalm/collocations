#!/usr/bin/env python

# filter single character tokens that are not a char
# and also filter -RRB- and -LRB- (maybe better to even remove contents?) 
# eg ['this','|','ain',"'",'t','good'] => ['this','ain','t','good']

import sys

def alpha_numeric(t): 
    return t.isdigit() or (t.lower() >= 'a' and t.lower() <= 'z')

def keep(t):
    if t == '-RRB-' or t=='-LRB-': 
        return False
    for c in t:
        if alpha_numeric(c):
            return True
    return False

for line in sys.stdin:
    tokens = line.strip().split()
    tokens = filter(keep, tokens)
    print " ".join(tokens)
