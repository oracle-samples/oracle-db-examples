#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ArrayDMLRowCounts.py
#
# Demonstrate the use of the 12.1 feature that allows cursor.executemany()
# to return the number of rows affected by each individual execution as a list.
# The parameter "arraydmlrowcounts" must be set to True in the call to
# cursor.executemany() after which cursor.getarraydmlrowcounts() can be called.
#
# This script requires cx_Oracle 5.2 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
cursor = connection.cursor()

# show the number of rows for each parent ID as a means of verifying the
# output from the delete statement
for parentId, count in cursor.execute("""
        select ParentId, count(*)
        from ChildTable
        group by ParentId
        order by ParentId"""):
    print("Parent ID:", parentId, "has", int(count), "rows.")
print()

# delete the following parent IDs only
parentIdsToDelete = [20, 30, 50]

print("Deleting Parent IDs:", parentIdsToDelete)
print()

# enable array DML row counts for each iteration executed in executemany()
cursor.executemany("""
        delete from ChildTable
        where ParentId = :1""",
        [(i,) for i in parentIdsToDelete],
        arraydmlrowcounts = True)

# display the number of rows deleted for each parent ID
rowCounts = cursor.getarraydmlrowcounts()
for parentId, count in zip(parentIdsToDelete, rowCounts):
    print("Parent ID:", parentId, "deleted", count, "rows.")

