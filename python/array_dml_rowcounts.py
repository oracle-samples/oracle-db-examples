#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# array_dml_rowcounts.py
#
# Demonstrate the use of the 12.1 feature that allows cursor.executemany()
# to return the number of rows affected by each individual execution as a list.
# The parameter "arraydmlrowcounts" must be set to True in the call to
# cursor.executemany() after which cursor.getarraydmlrowcounts() can be called.
#
# This script requires cx_Oracle 5.2 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()

# show the number of rows for each parent ID as a means of verifying the
# output from the delete statement
for parent_id, count in cursor.execute("""
        select ParentId, count(*)
        from ChildTable
        group by ParentId
        order by ParentId"""):
    print("Parent ID:", parent_id, "has", int(count), "rows.")
print()

# delete the following parent IDs only
parent_ids_to_delete = [20, 30, 50]

print("Deleting Parent IDs:", parent_ids_to_delete)
print()

# enable array DML row counts for each iteration executed in executemany()
cursor.executemany("""
        delete from ChildTable
        where ParentId = :1""",
        [(i,) for i in parent_ids_to_delete],
        arraydmlrowcounts = True)

# display the number of rows deleted for each parent ID
row_counts = cursor.getarraydmlrowcounts()
for parent_id, count in zip(parent_ids_to_delete, row_counts):
    print("Parent ID:", parent_id, "deleted", count, "rows.")
