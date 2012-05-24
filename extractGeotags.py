#!/usr/bin/python

import sys, pdb, re

if len(sys.argv) < 3:
	sys.exit("Usage: extractGeotags.py <geotags_file> <list_file> [-k]")

geotags_file = sys.argv[1]
list_file = sys.argv[2]

# Options
output_kml = 0;
print_cid = 0;
for i in range(3, len(sys.argv)):
	if sys.argv[i] == '-k':
		output_kml = 1
	elif sys.argv[i] == '-c':
		print_cid = 1
	else:
		sys.exit("Unrecognized option: %s" % sys.argv[i])

sys.stderr.write('Read list file %s ...\n' % list_file)
file_list = {}
fp = open(list_file, 'r')
cid = 1;
for line in fp:
	cols = line.rstrip().split()
	img_name = re.search('/?([^/]+)\.(jpg|JPG)', cols[0]).group(1)
	#print img_name
	file_list[img_name] = cid		# Store CID in file_list
	cid = cid + 1
fp.close()

#pdb.set_trace()

sys.stderr.write('Read geotags file %s ...\n' % geotags_file)

if output_kml:
	print '<?xml version="1.0" encoding="UTF-8"?>'
	print '<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">'
	print '    <Folder>'
	print '        <name>Locations from Bundler</name>'
 	print '       <Style id="dot">'
 	print '           <IconStyle>'
 	print '               <scale>0.3</scale>'
 	print '               <Icon>'
	print '                   <href>http://www.cs.cornell.edu/w8/~cpwang/Landmarks3/images/greenDot.png</href>'
 	print '               </Icon>'
 	print '           </IconStyle>'
 	print '       </Style>'

fp = open(geotags_file, 'r')
for line in fp:
	cols = line.rstrip().split()
	img_name = re.search('/?([^/]+?)(\.(jpg|JPG))?$', cols[0]).group(1)
	#print img_name
	lat = cols[1]
	lng = cols[2]
	if file_list.has_key(img_name):
		if output_kml:
			print '        <Placemark>'
 			print '           <description></description>'
 			print '           <styleUrl>#dot</styleUrl>'
 			print '           <Point>'
 			print '               <coordinates>%s,%s</coordinates>' % (lng, lat)
 			print '           </Point>'
 			print '       </Placemark>'
		elif print_cid:
			print '%d\t%s\t%s' % (file_list[img_name], lat, lng)
		else:
			print '%s\t%s' % (lat, lng)
	
fp.close()

if output_kml:
	print '    </Folder>'
	print '</kml>'

