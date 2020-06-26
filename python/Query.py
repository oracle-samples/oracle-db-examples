#------------------------------------------------------------------------------
# Copyright (c) 2016, 2020, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Query.py
#
# Demonstrate how to perform a query in different ways.
#------------------------------------------------------------------------------

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
print()

print("Fetch each row as a Dictionary")
cursor.execute(sql)
columns = [col[0] for col in cursor.description]
cursor.rowfactory = lambda *args: dict(zip(columns, args))
for row in cursor:
    print(row)
