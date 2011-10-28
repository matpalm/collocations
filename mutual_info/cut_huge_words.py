#!/usr/bin/env python
import sys

def filter_huge_words(token):
    if token.startswith("http"):
        return "URL"
    elif len(token)>100:
        return "LONGTERM"
    else:
        return token
    
for line in sys.stdin:
    print " ".join(map(filter_huge_words, line.split()))
    
