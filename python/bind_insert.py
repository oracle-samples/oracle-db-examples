#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# bind_insert.py
#
# Demonstrate how to insert a row into a table using bind variables.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

#------------------------------------------------------------------------------
# "Bind by position"
#------------------------------------------------------------------------------

rows = [
    (1, "First"),
    (2, "Second"),
    (3, "Third"),
    (4, "Fourth"),
    (5, None),     # Insert a NULL value
    (6, "Sixth"),
    (7, "Seventh")
]

cursor = connection.cursor()

# predefine maximum string size to avoid data scans and memory reallocations;
# the None value indicates that the default processing can take place
cursor.setinputsizes(None, 20)

cursor.executemany("insert into mytab(id, data) values (:1, :2)", rows)

#------------------------------------------------------------------------------
# "Bind by name"
#------------------------------------------------------------------------------

rows = [
    {"d": "Eighth", "i": 8},
    {"d": "Ninth",  "i": 9},
    {"d": "Tenth",  "i": 10}
]

cursor = connection.cursor()

# Predefine maximum string size to avoid data scans and memory reallocations
cursor.setinputsizes(d=20)

cursor.executemany("insert into mytab(id, data) values (:i, :d)", rows)

#------------------------------------------------------------------------------
# Inserting a single bind still needs tuples
#------------------------------------------------------------------------------

rows = [
    ("Eleventh",),
    ("Twelth",)
]

cursor = connection.cursor()
cursor.executemany("insert into mytab(id, data) values (11, :1)", rows)

#------------------------------------------------------------------------------
# Now query the results back
#------------------------------------------------------------------------------

# Don't commit - this lets the demo be run multiple times
#connection.commit()

for row in cursor.execute('select * from mytab'):
    print(row)
