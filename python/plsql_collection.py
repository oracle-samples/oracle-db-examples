#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# plsql_collection.py
#
# Demonstrate how to get the value of a PL/SQL collection from a stored
# procedure.
#
# This feature is new in cx_Oracle 5.3 and is only available in Oracle
# Database 12.1 and higher. The ability to get the collection as a dictionary
# is new in cx_Oracle 7.0.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

# create new empty object of the correct type
# note the use of a PL/SQL type defined in a package
type_obj = connection.gettype("PKG_DEMO.UDT_STRINGLIST")
obj = type_obj.newobject()

# call the stored procedure which will populate the object
cursor = connection.cursor()
cursor.callproc("pkg_Demo.DemoCollectionOut", (obj,))

# show the indexes that are used by the collection
print("Indexes and values of collection:")
ix = obj.first()
while ix is not None:
    print(ix, "->", obj.getelement(ix))
    ix = obj.next(ix)
print()

# show the values as a simple list
print("Values of collection as list:")
print(obj.aslist())
print()

# show the values as a simple dictionary
print("Values of collection as dictionary:")
print(obj.asdict())
print()
