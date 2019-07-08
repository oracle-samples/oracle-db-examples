#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# BindInsert.py
#
# Demonstrate how to insert a row into a table using bind variables.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())

rows = [ (1, "First" ),
         (2, "Second" ),
         (3, "Third" ),
         (4, "Fourth" ),
         (5, "Fifth" ),
         (6, "Sixth" ),
         (7, "Seventh" ) ]

cursor = connection.cursor()
cursor.executemany("insert into mytab(id, data) values (:1, :2)", rows)

# Don't commit - this lets us run the demo multiple times
#connection.commit()

# Now query the results back

for row in cursor.execute('select * from mytab'):
    print(row)

