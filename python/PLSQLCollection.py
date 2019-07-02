#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# PLSQLCollection.py
#
# Demonstrate how to get the value of a PL/SQL collection from a stored
# procedure.
#
# This feature is new in cx_Oracle 5.3 and is only available in Oracle
# Database 12.1 and higher. The ability to get the collection as a dictionary
# is new in cx_Oracle 7.0.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())

# create new empty object of the correct type
# note the use of a PL/SQL type defined in a package
typeObj = connection.gettype("PKG_DEMO.UDT_STRINGLIST")
obj = typeObj.newobject()

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

