#------------------------------------------------------------------------------
# Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# dml_returning_multiple_rows.py
#   This script demonstrates the use of DML returning with multiple rows being
# returned at once.
#
# This script requires cx_Oracle 6.0 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

# truncate table first so that script can be rerun
connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()
print("Truncating table...")
cursor.execute("truncate table TestTempTable")

# populate table with a few rows
for i in range(5):
    data = (i + 1, "Test String #%d" % (i + 1))
    print("Adding row", data)
    cursor.execute("insert into TestTempTable values (:1, :2)", data)

# now delete them and use DML returning to return the data that was inserted
int_col = cursor.var(int)
string_col = cursor.var(str)
print("Deleting data with DML returning...")
cursor.execute("""
        delete from TestTempTable
        returning IntCol, StringCol into :int_col, :string_col""",
        int_col=int_col,
        string_col=string_col)
print("Data returned:")
for int_val, string_val in zip(int_col.getvalue(), string_col.getvalue()):
    print(tuple([int_val, string_val]))
