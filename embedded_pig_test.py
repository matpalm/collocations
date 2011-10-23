#!/usr/bin/python
from org.apache.pig.scripting import *

def main():
    P = Pig.compile("""
x = load 'numbers';
y = filter x by $0>3;
store y into '$out';
"""
)
    out = 'test.out'
    job = P.bind().runSingle()
    print 'success?', job.isSuccessful()
    print 'result', job.result('out')


if __name__ == '__main__':
    main()
