#------------------------------------------------------------------------------
# Copyright (c) 2017, 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# DMLReturningMultipleRows.py
#   This script demonstrates the use of DML returning with multiple rows being
# returned at once.
#
# This script requires cx_Oracle 6.0 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import datetime
import SampleEnv

# truncate table first so that script can be rerun
connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
cursor = connection.cursor()
print("Truncating table...")
cursor.execute("truncate table TestTempTable")

# populate table with a few rows
for i in range(5):
    data = (i + 1, "Test String #%d" % (i + 1))
    print("Adding row", data)
    cursor.execute("insert into TestTempTable values (:1, :2)", data)

# now delete them and use DML returning to return the data that was inserted
intCol = cursor.var(int)
stringCol = cursor.var(str)
print("Deleting data with DML returning...")
cursor.execute("""
        delete from TestTempTable
        returning IntCol, StringCol into :intCol, :stringCol""",
        intCol = intCol,
        stringCol = stringCol)
print("Data returned:")
for intVal, stringVal in zip(intCol.getvalue(), stringCol.getvalue()):
    print(tuple([intVal, stringVal]))

