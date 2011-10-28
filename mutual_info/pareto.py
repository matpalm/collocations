#!/usr/bin/env python
import sys

x = {}
y = {}
keys = []
original_rank = {}
rank = 1
for line in sys.stdin:
    c,px,py = line.strip().split("\t")
    x[c] = float(px)
    y[c] = float(py)
    keys.append(c)
    original_rank[c] = rank
    rank+=1
num_in_front = {}

max_allowed_in_front = 1#nint(len(keys) * 0.005)
#sys.stderr.write("max_allowed_in_front "+str(max_allowed_in_front)+"\n")

def on_front(p1):
    num_in_front_of_p1 = 0
    p1x = x[p1]
    for p2 in keys:
        if p1 == p2: continue
        p2x = x[p2]
        if p2x < p1x: continue
        #print "comparing",p1,"(",p1x,y[p1],") to",p2,"(",p2x,y[p2],")"
        if y[p1] <= y[p2]:
            num_in_front_of_p1 += 1
            if num_in_front_of_p1 > max_allowed_in_front:
                return False
    #print p1,"is on front"
    num_in_front[p1] = num_in_front_of_p1
    return True

pareto = []
for p1 in keys:
    if on_front(p1):
        pareto.append(p1)

for k in pareto:
    print "\t".join(map(str,[original_rank[k], k, x[k], y[k], num_in_front[k]]))

