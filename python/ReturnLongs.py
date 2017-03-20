#------------------------------------------------------------------------------
# Copyright 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ReturnLongs.py
#   Returns all CLOB values as long strings and BLOB values as long raws. This
# is only useful if the lengths of the CLOB and BLOB values are well known but
# it can improve performance because there is no need to return to the database
# to get the actual values.
#
# This script requires cx_Oracle 5.0 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

def OutputTypeHandler(cursor, name, defaultType, size, precision, scale):
    if defaultType == cx_Oracle.CLOB:
        return cursor.var(cx_Oracle.LONG_STRING, 80000, cursor.arraysize)
    if defaultType == cx_Oracle.BLOB:
        return cursor.var(cx_Oracle.LONG_BINARY, 100004, cursor.arraysize)

connection = cx_Oracle.Connection("cx_Oracle/dev@localhost/orcl")
connection.outputtypehandler = OutputTypeHandler
cursor = connection.cursor()
print("CLOBS returned as longs")
cursor.execute("""
        select
          IntCol,
          ClobCol
        from TestClobs
        where dbms_lob.getlength(ClobCol) <= 80000
        order by IntCol""")
for intCol, value in cursor:
    print("Row:", intCol, "string of length", len(value))
print()
print("BLOBS returned as longs")
cursor.execute("""
        select
          IntCol,
          BlobCol
        from TestBlobs
        where dbms_lob.getlength(BlobCol) <= 100000
        order by IntCol""")
for intCol, value in cursor:
    print("Row:", intCol, "string of length", value and len(value) or 0)

