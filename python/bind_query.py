#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# bind_query.py
#
# Demonstrate how to perform a simple query limiting the rows retrieved using
# a bind variable. Since the query that is executed is identical, no additional
# parsing is required, thereby reducing overhead and increasing performance. It
# also permits data to be bound without having to be concerned about escaping
# special characters or SQL injection attacks.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

cursor = connection.cursor()
sql = 'select * from SampleQueryTab where id = :bvid'

print("Query results with id = 4")
for row in cursor.execute(sql, bvid = 4):
    print(row)
print()

print("Query results with id = 1")
for row in cursor.execute(sql, bvid = 1):
    print(row)
print()
