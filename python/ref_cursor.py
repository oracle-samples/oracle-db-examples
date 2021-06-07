#------------------------------------------------------------------------------
# Copyright (c) 2018, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ref_cursor.py
#   Demonstrates the use of REF cursors with cx_Oracle.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()

ref_cursor = connection.cursor()
cursor.callproc("myrefcursorproc", (2, 6, ref_cursor))
print("Rows between 2 and 6:")
for row in ref_cursor:
    print(row)
print()

ref_cursor = connection.cursor()
cursor.callproc("myrefcursorproc", (8, 9, ref_cursor))
print("Rows between 8 and 9:")
for row in ref_cursor:
    print(row)
print()

#------------------------------------------------------------------------------
# Setting prefetchrows and arraysize of a REF cursor can improve performance
# when fetching a large number of rows (Tuned Fetch)
#------------------------------------------------------------------------------

# Truncate the table used for this demo
cursor.execute("truncate table TestTempTable")

# Populate the table with a large number of rows
num_rows = 50000
sql = "insert into TestTempTable (IntCol) values (:1)"
data = [(n + 1,) for n in range(num_rows)]
cursor.executemany(sql, data)

# Set the arraysize and prefetch rows of the REF cursor
ref_cursor = connection.cursor()
ref_cursor.prefetchrows = 1000
ref_cursor.arraysize = 1000

# Perform the tuned fetch
sum_rows = 0
cursor.callproc("myrefcursorproc2", [ref_cursor])
print("Sum of IntCol for", num_rows, "rows:")
for row in ref_cursor:
    sum_rows += row[0]
print(sum_rows)
