#!/usr/bin/env python
import sys
for line in sys.stdin:
    if len(line.split()) > 100:
	print line
