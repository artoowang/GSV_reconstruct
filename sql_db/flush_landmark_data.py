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

cursor.execute ("DROP TABLE IF EXISTS LandmarkProperties")
cursor.execute ("DROP TABLE IF EXISTS Components")
cursor.execute ("DROP TABLE IF EXISTS Landmarks")

cursor.execute ("""
    CREATE TABLE Landmarks (
        tags varchar(512), # tags of a landmark
        lid int NOT NULL, # landmark id
        PRIMARY KEY(lid)
    )
    """)
cursor.execute ("""
    CREATE TABLE LandmarkProperties (
    # landmark id, primary and uniquely defines entries. (entries in this table 1-1 corresponds to entry in Landmarks)
    lid int,
    FOREIGN KEY (lid) REFERENCES Landmarks(lid), 
    PRIMARY KEY (lid),
    
    # Count of components
    component_count int,

    # Global lock
    global_lock int, 
    global_lock_holder varchar(128), 

    # Other useful fields
    cleaned int, 
    processed int, 
    processing_detail varchar(128)
    )
    """)
cursor.execute ("""
CREATE INDEX index1 ON Landmarks (lid);
""")

cursor.execute ("""
CREATE INDEX index2 ON LandmarkProperties (lid);
""")

insertStr1 = "INSERT INTO Landmarks (lid, tags) VALUES "
insertStr2 = "INSERT INTO LandmarkProperties (lid, component_count, global_lock, cleaned, processed) VALUES "

lmfile = open('lid.txt', 'r')
prog = re.compile('^([0-9]+)\s+\S+\s+\S+\s+\S+\s+\S+\s+(.*)$')

for line in lmfile:
    m = prog.match(line)
    if not m:
        continue
    insertStr1 += ('(' + m.group(1) + ', \'' + m.group(2)+ '\'),')
    insertStr2 += ('(' + m.group(1) + ', 0, 0, 0, 0),')
insertStr1 = insertStr1[0:len(insertStr1)-1]
insertStr2 = insertStr2[0:len(insertStr2)-1]

cursor.execute(insertStr1)
cursor.execute(insertStr2)

cursor.close ()
conn.close ()
