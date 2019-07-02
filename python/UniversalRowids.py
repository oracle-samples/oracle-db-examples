#------------------------------------------------------------------------------
# Copyright (c) 2017, 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# UniversalRowids.py
#   This script demonstrates the use of universal rowids. Universal rowids are
# used to identify rows in index organized tables.
#
# This script requires cx_Oracle 6.0 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import datetime
import SampleEnv

DATA = [
    (1, "String #1", datetime.datetime(2017, 4, 4)),
    (2, "String #2", datetime.datetime(2017, 4, 5)),
    (3, "A" * 250, datetime.datetime(2017, 4, 6))
]

# truncate table so sample can be rerun
connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
cursor = connection.cursor()
print("Truncating table...")
cursor.execute("truncate table TestUniversalRowids")

# populate table with a few rows
print("Populating table...")
for row in DATA:
    print("Inserting", row)
    cursor.execute("insert into TestUniversalRowids values (:1, :2, :3)", row)
connection.commit()

# fetch the rowids from the table
rowids = [r for r, in cursor.execute("select rowid from TestUniversalRowids")]

# fetch each of the rows given the rowid
for rowid in rowids:
    print("-" * 79)
    print("Rowid:", rowid)
    cursor.execute("""
            select IntCol, StringCol, DateCol
            from TestUniversalRowids
            where rowid = :rid""",
            rid = rowid)
    intCol, stringCol, dateCol = cursor.fetchone()
    print("IntCol:", intCol)
    print("StringCol:", stringCol)
    print("DateCol:", dateCol)

