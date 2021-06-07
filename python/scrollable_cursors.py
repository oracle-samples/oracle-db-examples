#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# scrollable_cursors.py
#   This script demonstrates how to use scrollable cursors. These allow moving
# forward and backward in the result set but incur additional overhead on the
# server to retain this information.
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

# show all of the rows available in the table
cursor = connection.cursor()
cursor.execute("select * from TestStrings order by IntCol")
print("ALL ROWS")
for row in cursor:
    print(row)
print()

# create a scrollable cursor
cursor = connection.cursor(scrollable = True)

# set array size smaller than the default (100) to force scrolling by the
# database; otherwise, scrolling occurs directly within the buffers
cursor.arraysize = 3
cursor.execute("select * from TestStrings order by IntCol")

# scroll to last row in the result set; the first parameter is not needed and
# is ignored)
cursor.scroll(mode = "last")
print("LAST ROW")
print(cursor.fetchone())
print()

# scroll to the first row in the result set; the first parameter not needed and
# is ignored
cursor.scroll(mode = "first")
print("FIRST ROW")
print(cursor.fetchone())
print()

# scroll to an absolute row number
cursor.scroll(5, mode = "absolute")
print("ROW 5")
print(cursor.fetchone())
print()

# scroll forward six rows (the mode parameter defaults to relative)
cursor.scroll(3)
print("SKIP 3 ROWS")
print(cursor.fetchone())
print()

# scroll backward four rows (the mode parameter defaults to relative)
cursor.scroll(-4)
print("SKIP BACK 4 ROWS")
print(cursor.fetchone())
print()
