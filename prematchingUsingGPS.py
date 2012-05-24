#!/usr/bin/python

import sys, pdb, re, math

if len(sys.argv) < 5:
	sys.exit("Usage: %s <image_list_file> <num_NN> <num_nodes> <prematch_path>" % sys.argv[0])

list_file = sys.argv[1]
num_NN = int(sys.argv[2])
num_nodes = int(sys.argv[3])
prematch_path = sys.argv[4]

photos = []
# Load image list file
print 'Read list file %s ...' % list_file
fp = open(list_file, 'r')
for line in fp:
	result = re.search('/?([0-9.-]+)_([0-9.-]+)_([0-9.-]+)_[0-9.-]+\.(jpg|JPG)', line)
	lat = float(result.group(1))
	lng = float(result.group(2))
	azi = float(result.group(3))
	photos.append({'lat': lat, 'lng': lng, 'azi': azi, 'matches': {}})
	#print '%.2f %.2f %.2f' % (lat, lng, azi)
fp.close()
print '%d photos loaded.' % len(photos)

# Search for num_NN nearest neighbors for each photo

# Assign 3 jobs to each node 
# (note: currently I don't really divide the jobs to several nodes. I just want to simulate what is done inside BundlerPipeline5.sh by divideMatchingProblem.py)
num_photos = len(photos)
num_jobs = num_nodes * 3
num_photo_per_job = int(math.ceil(float(num_photos)/num_jobs))
epsilon = 1e-10		# Avoid dividing by zero for the photos that are at the same place

print 'num_jobs = %d' % num_jobs
print 'num_photo_per_job = %d' % num_photo_per_job

for jid in range(0, num_jobs):
#for jid in range(0, 1):
	file_name = '%s/prematch_%03d.txt' % (prematch_path, jid)
	fp = open(file_name, 'w')
	print 'Write to %s ...' % file_name
	for i in range(jid*num_photo_per_job, min((jid+1)*num_photo_per_job, num_photos)):
		if i % 10 == 0:
			sys.stdout.write('...%d' % i)
			sys.stdout.flush()

		d = []
		for j in range(0, num_photos):
			if i == j:
				d.append((j, float("inf")))	# Avoid matching image to itself by setting distance to infinity
			else:
				d.append((j, math.sqrt(math.pow(photos[i]['lat']-photos[j]['lat'],2) + math.pow(photos[i]['lng']-photos[j]['lng'],2))))
		d = sorted(d, key=lambda t: t[1])	# Sort by distance (lambda: anonymous function)
		#print d[0:num_NN]
		for j in range(0, num_NN):
			id = d[j][0]
			score = 1/(d[j][1]+epsilon)
			#print '%d %d %e' % (i, id, score)	# Use the reciprocal of distance as matching score
			fp.write('%d %d %e\n' % (i, id, score))
			if id < i:
				photos[i]['matches'][id] = score
			elif id > i:
				photos[id]['matches'][i] = score
			else:
				raise Exception('Shoud not be here')
			
	print ''
	fp.close()

# Handle prematch.full
file_name = '%s/prematch.full' % prematch_path
fp = open(file_name, 'w')
print 'Write to %s ...' % file_name
for i in range(0, num_photos):
	matches = sorted(photos[i]['matches'].items(), key=lambda t: t[0])	# Sort by ID
	for m in matches:
		fp.write('%d %d %e\n' % (i, m[0], m[1]))
fp.close()

