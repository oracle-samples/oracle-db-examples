#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Query.py
#
# Demonstrate how to perform a query in different ways.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())

sql = """
        select * from SampleQueryTab
        where id < 6
        order by id"""

print("Get all rows via iterator")
cursor = connection.cursor()
for result in cursor.execute(sql):
    print(result)
print()

print("Query one row at a time")
cursor.execute(sql)
row = cursor.fetchone()
print(row)
row = cursor.fetchone()
print(row)
print()

print("Fetch many rows")
cursor.execute(sql)
res = cursor.fetchmany(numRows=3)
print(res)

