#!/usr/bin/python
import sys
import MySQLdb
import re

try:
    conn = MySQLdb.connect (host = "web8.cs.cornell.edu",
                            user = "yc489",
                            passwd = "m2JKcb5aHa",
                            db = "landmarks")
except MySQLdb.Error, e:
    print "Error %d: %s" % (e.args[0], e.args[1])
    sys.exit (1)

cursor = conn.cursor ()

cursor.execute ("DROP TABLE IF EXISTS Components")

cursor.execute ("""
    CREATE TABLE Components (
    cid varchar(32) NOT NULL, # component id (1008.01)
    lid int NOT NULL, # the landmark this component is associated with 
    suffix varchar(32), # suffix of the component (gsv)
    CONSTRAINT component_identifier PRIMARY KEY (lid, cid, suffix), # component's identifier

    total_count int, # total number of photos
    registered_count int, # the number of registered photos

    # Global lock
    global_lock int, 
    global_lock_holder varchar(128), 

    # Process locks. Add pairs of (lock, lock holder) for each process desired to be locked. 
    # Add more as we discovers
    gsv_lock int, 
    gsv_lock_holder varchar(128)
    )
        """)

cpfile = open('stats.txt', 'r')
prog1 = re.compile('^([0-9]+)\s+status:\s+([012])(\s+good_components:\s+([0-9]+)\s+clean:\s+([01]))?')
prog2 = re.compile('^component\s+([0-9.]+):\s+([-0-9]+)\s+out of\s+([-0-9]+)\s+reconstructed')

insertStr1 = "UPDATE LandmarkProperties SET processed = %d, component_count = %d, cleaned = %d WHERE lid = %d"
insertStr2 = "INSERT INTO Components (cid, lid, suffix, total_count, registered_count, global_lock, gsv_lock) VALUES "

while True:
    line = cpfile.readline()
    if len(line) == 0: 
        break
    line = line.strip()

    m = prog1.match(line)
    if not m:
        continue

    lid = int(m.group(1))
    processed = int(m.group(2))
    if m.group(4) == None:
        components = 0
    else:
        components = int(m.group(4))

    if m.group(5) == None:
        cleaned = 0
    else:
        cleaned = int(m.group(5))

    cursor.execute(insertStr1%(processed, components, cleaned, lid))

    for i in range(0, components):
        line2 = cpfile.readline().strip()
        m2 = prog2.match(line2)
        if not m2:
            print "unrecognized line. "
            continue
        insertStr2 += ('(\''+m2.group(1)+'\', '+str(lid)+', \'\', '+m2.group(3)+', '+m2.group(2)+', 0, 0),') 

insertStr2 = insertStr2[0:len(insertStr2)-1]
cursor.execute(insertStr2)
cursor.close()
conn.close()
