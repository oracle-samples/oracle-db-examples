#------------------------------------------------------------------------------
# InsertGeometry.py
#   This script demonstrates the ability to create Oracle objects (this example
# uses SDO_GEOMETRY) and insert them into a table.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

# create and populate Oracle objects
connection = cx_Oracle.Connection("cx_Oracle/dev@localhost/orcl")
typeObj = connection.gettype("SDO_GEOMETRY")
elementInfoTypeObj = connection.gettype("SDO_ELEM_INFO_ARRAY")
ordinateTypeObj = connection.gettype("SDO_ORDINATE_ARRAY")
obj = typeObj.newobject()
obj.SDO_GTYPE = 2003
obj.SDO_ELEM_INFO = elementInfoTypeObj.newobject()
obj.SDO_ELEM_INFO.extend([1, 1003, 3])
obj.SDO_ORDINATES = ordinateTypeObj.newobject()
obj.SDO_ORDINATES.extend([1, 1, 5, 7])
print("Created object", obj)

# create table, if necessary
cursor = connection.cursor()
cursor.execute("""
        select count(*)
        from user_tables
        where table_name = 'TESTGEOMETRY'""")
count, = cursor.fetchone()
if count == 0:
    print("Creating table...")
    cursor.execute("""
            create table TestGeometry (
                IntCol number(9) not null,
                Geometry SDO_GEOMETRY not null
            )""")

# remove all existing rows and then add a new one
print("Removing any existing rows...")
cursor.execute("delete from TestGeometry")
print("Adding row to table...")
cursor.execute("insert into TestGeometry values (1, :obj)", obj = obj)
connection.commit()
print("Success!")

