#!/usr/bin/env python
import sys
for line in sys.stdin:
    tokens = line.strip().split("\t")
    if len(tokens)!=3:
        sys.stderr.write("reporter:counter:check,not_three_tokens,1\n")
    else:
        for token in tokens:
            sys.stderr.write("reporter:counter:check,token_len_"+str(len(token))+",1\n")

