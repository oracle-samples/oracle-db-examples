#------------------------------------------------------------------------------
# Copyright (c) 2019, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# last_rowid.py
#   Demonstrates the use of the cursor.lastrowid attribute.
#
# This script requires cx_Oracle 7.3 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

row1 = [1, "First"]
row2 = [2, "Second"]

# insert a couple of rows and retain the rowid of each
cursor = connection.cursor()
cursor.execute("insert into mytab (id, data) values (:1, :2)", row1)
rowid1 = cursor.lastrowid
print("Row 1:", row1)
print("Rowid 1:", rowid1)
print()

cursor.execute("insert into mytab (id, data) values (:1, :2)", row2)
rowid2 = cursor.lastrowid
print("Row 2:", row2)
print("Rowid 2:", rowid2)
print()

# the row can be fetched with the rowid that was retained
cursor.execute("select id, data from mytab where rowid = :1", [rowid1])
print("Row 1:", cursor.fetchone())
cursor.execute("select id, data from mytab where rowid = :1", [rowid2])
print("Row 2:", cursor.fetchone())
print()

# updating multiple rows only returns the rowid of the last updated row
cursor.execute("update mytab set data = data || ' (Modified)'")
cursor.execute("select id, data from mytab where rowid = :1",
        [cursor.lastrowid])
print("Last updated row:", cursor.fetchone())

# deleting multiple rows only returns the rowid of the last deleted row
cursor.execute("delete from mytab")
print("Rowid of last deleted row:", cursor.lastrowid)

# deleting no rows results in a value of None
cursor.execute("delete from mytab")
print("Rowid when no rows are deleted:", cursor.lastrowid)

# Don't commit - this lets us run the demo multiple times
#connection.commit()
