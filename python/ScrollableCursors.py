#------------------------------------------------------------------------------
# Copyright 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ScrollableCursors.py
#   This script demonstrates how to use scrollable cursors. These allow moving
# forward and backward in the result set but incur additional overhead on the
# server to retain this information.
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

con = cx_Oracle.connect("cx_Oracle/dev@localhost/orcl")

# show all of the rows available in the table
cur = con.cursor()
cur.execute("select * from TestStrings order by IntCol")
print("ALL ROWS")
for row in cur:
    print(row)
print()

# create a scrollable cursor
cur = con.cursor(scrollable = True)

# set array size smaller than the default (100) to force scrolling by the
# database; otherwise, scrolling occurs directly within the buffers
cur.arraysize = 3
cur.execute("select * from TestStrings order by IntCol")

# scroll to last row in the result set; the first parameter is not needed and
# is ignored)
cur.scroll(mode = "last")
print("LAST ROW")
print(cur.fetchone())
print()

# scroll to the first row in the result set; the first parameter not needed and
# is ignored
cur.scroll(mode = "first")
print("FIRST ROW")
print(cur.fetchone())
print()

# scroll to an absolute row number
cur.scroll(5, mode = "absolute")
print("ROW 5")
print(cur.fetchone())
print()

# scroll forward six rows (the mode parameter defaults to relative)
cur.scroll(3)
print("SKIP 3 ROWS")
print(cur.fetchone())
print()

# scroll backward four rows (the mode parameter defaults to relative)
cur.scroll(-4)
print("SKIP BACK 4 ROWS")
print(cur.fetchone())
print()

