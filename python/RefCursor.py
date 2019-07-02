#------------------------------------------------------------------------------
# Copyright (c) 2018, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# RefCursor.py
#   Demonstrates the use of REF cursors with cx_Oracle.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
cursor = connection.cursor()

refCursor = connection.cursor()
cursor.callproc("myrefcursorproc", (2, 6, refCursor))
print("Rows between 2 and 6:")
for row in refCursor:
    print(row)
print()

refCursor = connection.cursor()
cursor.callproc("myrefcursorproc", (8, 9, refCursor))
print("Rows between 8 and 9:")
for row in refCursor:
    print(row)
print()

