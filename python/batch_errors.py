#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# batch_errors.py
#
# Demonstrate the use of the Oracle Database 12.1 feature that allows
# cursor.executemany() to complete successfully, even if errors take
# place during the execution of one or more of the individual
# executions. The parameter "batcherrors" must be set to True in the
# call to cursor.executemany() after which cursor.getbatcherrors() can
# be called, which will return a list of error objects.
#
# This script requires cx_Oracle 5.2 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()

# define data to insert
data_to_insert = [
    (1016, 10, 'Child B of Parent 10'),
    (1017, 10, 'Child C of Parent 10'),
    (1018, 20, 'Child D of Parent 20'),
    (1018, 20, 'Child D of Parent 20'),       # duplicate key
    (1019, 30, 'Child C of Parent 30'),
    (1020, 30, 'Child D of Parent 40'),
    (1021, 60, 'Child A of Parent 60'),       # parent does not exist
    (1022, 40, 'Child F of Parent 40'),
]

# retrieve the number of rows in the table
cursor.execute("""
        select count(*)
        from ChildTable""")
count, = cursor.fetchone()
print("number of rows in child table:", int(count))
print("number of rows to insert:", len(data_to_insert))

# old method: executemany() with data errors results in stoppage after the
# first error takes place; the row count is updated to show how many rows
# actually succeeded
try:
    cursor.executemany("insert into ChildTable values (:1, :2, :3)",
                       data_to_insert)
except oracledb.DatabaseError as e:
    error, = e.args
    print("FAILED with error:", error.message)
    print("number of rows which succeeded:", cursor.rowcount)

# demonstrate that the row count is accurate
cursor.execute("""
        select count(*)
        from ChildTable""")
count, = cursor.fetchone()
print("number of rows in child table after failed insert:", int(count))

# roll back so we can perform the same work using the new method
connection.rollback()

# new method: executemany() with batch errors enabled (and array DML row counts
# also enabled) results in no immediate error being raised
cursor.executemany("insert into ChildTable values (:1, :2, :3)",
                   data_to_insert, batcherrors=True, arraydmlrowcounts=True)

# where errors have taken place, the row count is 0; otherwise it is 1
row_counts = cursor.getarraydmlrowcounts()
print("Array DML row counts:", row_counts)

# display the errors that have taken place
errors = cursor.getbatcherrors()
print("number of errors which took place:", len(errors))
for error in errors:
    print("Error", error.message.rstrip(), "at row offset", error.offset)

# demonstrate that all of the rows without errors have been successfully
# inserted
cursor.execute("""
        select count(*)
        from ChildTable""")
count, = cursor.fetchone()
print("number of rows in child table after successful insert:", int(count))
