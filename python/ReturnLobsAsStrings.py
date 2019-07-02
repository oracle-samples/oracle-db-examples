#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ReturnLobsAsStrings.py
#   Returns all CLOB values as strings and BLOB values as bytes. The
# performance of this technique is significantly better than fetching the LOBs
# and then reading the contents of the LOBs as it avoids round-trips to the
# database. Be aware, however, that this method requires contiguous memory so
# is not usable for very large LOBs.
#
# This script requires cx_Oracle 5.0 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

def OutputTypeHandler(cursor, name, defaultType, size, precision, scale):
    if defaultType == cx_Oracle.CLOB:
        return cursor.var(cx_Oracle.LONG_STRING, arraysize = cursor.arraysize)
    if defaultType == cx_Oracle.BLOB:
        return cursor.var(cx_Oracle.LONG_BINARY, arraysize = cursor.arraysize)

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
connection.outputtypehandler = OutputTypeHandler
cursor = connection.cursor()

# add some data to the tables
print("Populating tables with data...")
cursor.execute("truncate table TestClobs")
cursor.execute("truncate table TestBlobs")
longString = ""
for i in range(10):
    char = chr(ord('A') + i)
    longString += char * 25000
    # uncomment the line below for cx_Oracle 5.3 and earlier
    # cursor.setinputsizes(None, cx_Oracle.LONG_STRING)
    cursor.execute("insert into TestClobs values (:1, :2)",
            (i + 1, "STRING " + longString))
    # uncomment the line below for cx_Oracle 5.3 and earlier
    # cursor.setinputsizes(None, cx_Oracle.LONG_BINARY)
    cursor.execute("insert into TestBlobs values (:1, :2)",
            (i + 1, longString.encode("ascii")))
connection.commit()

# fetch the data and show the results
print("CLOBS returned as strings")
cursor.execute("""
        select
          IntCol,
          ClobCol
        from TestClobs
        order by IntCol""")
for intCol, value in cursor:
    print("Row:", intCol, "string of length", len(value))
print()
print("BLOBS returned as bytes")
cursor.execute("""
        select
          IntCol,
          BlobCol
        from TestBlobs
        order by IntCol""")
for intCol, value in cursor:
    print("Row:", intCol, "string of length", value and len(value) or 0)

