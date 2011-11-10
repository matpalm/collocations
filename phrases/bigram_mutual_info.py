#!/usr/bin/env python
import sys
from math import *
from collections import *

MIN_BIGRAM_SUPPORT = 3
MIN_UNIGRAM_SUPPORT = 8

unigram_count = 0
bigram_count = 0
unigram_freq = defaultdict(int)
bigram_freq = defaultdict(int)

# extract frequencies
for line in sys.stdin:
    tokens = line.strip().split()
    if len(tokens)==0:
        continue

    t1 = tokens.pop(0)
    unigram_freq[t1] += 1
    unigram_count += 1

    while len(tokens)>0:
        t2 = tokens.pop(0)
        unigram_freq[t2] += 1
        unigram_count += 1
        bigram = (t1,t2)
        bigram_freq[bigram] += 1
        bigram_count += 1
        t1 = t2

#print "unigram_count", unigram_count
#print "bigram_count", bigram_count

# emit mutual info
records = []
for bigram in bigram_freq:
    bigram_f = bigram_freq[bigram]
    if bigram_f == 1: # log(1) = 0 so final score always 0
        continue

    t1, t2 = bigram
    t1_f = unigram_freq[t1]
    t2_f = unigram_freq[t2]
#    if t1_f < MIN_UNIGRAM_SUPPORT or t2_f < MIN_UNIGRAM_SUPPORT:
#        continue

    # ll_bigram = log(bigram_f) - log(bigram_count)
    # ll_t1 = log(t1_f) - log(unigram_count)
    # ll_t2 = log(t2_f) - log(unigram_count)
    # mutual_info = exp(ll_bigram - (ll_t1 + ll_t2))

    mutual_info = log(bigram_f) - log(bigram_count) - log(t1_f) - log(t2_f) + 2*log(unigram_count)
    freq_mutual_info = log(bigram_f) * mutual_info
    records.append([t1,t2, bigram_f, mutual_info, freq_mutual_info])

for record in records:
    print "\t".join(map(str,record))


        
