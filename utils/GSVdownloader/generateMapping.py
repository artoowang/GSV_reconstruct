#!/usr/bin/python

import sys, re

if len(sys.argv) < 2:
	sys.exit("Usage: generateMapping.py <data_file>")

fpath = sys.argv[1]

fp = open(fpath, 'r')
for line in fp:
	cols = line.strip().split('\t')
	#print '%s %s %s %s' % (cols[0], cols[1], cols[2], cols[3])

	for i in range(7):
		rel_rot = float(i)*360/7
		abs_rot = (rel_rot + float(cols[4])) % 360
		print '%s %.4f -4 %s_%s_%.4f_-004.jpg' % (cols[0], rel_rot, cols[2], cols[3], abs_rot)
