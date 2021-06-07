#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# query.py
#
# Demonstrate how to perform a query in different ways.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

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
res = cursor.fetchmany(3)
print(res)
print()

print("Fetch each row as a Dictionary")
cursor.execute(sql)
columns = [col[0] for col in cursor.description]
cursor.rowfactory = lambda *args: dict(zip(columns, args))
for row in cursor:
    print(row)
