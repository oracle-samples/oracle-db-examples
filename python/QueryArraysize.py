#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# QueryArraysize.py
#
# Demonstrate how to alter the array size on a cursor in order to reduce the
# number of network round trips and overhead required to fetch all of the rows
# from a large table.
#------------------------------------------------------------------------------

from __future__ import print_function

import time
import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())

start = time.time()

cursor = connection.cursor()
cursor.arraysize = 1000
cursor.execute('select * from bigtab')
res = cursor.fetchall()
# print(res)  # uncomment to display the query results

elapsed = (time.time() - start)
print("Retrieved", len(res), "rows in", elapsed, "seconds")

