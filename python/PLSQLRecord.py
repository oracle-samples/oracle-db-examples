#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# PLSQLRecord.py
#
# Demonstrate how to bind (in and out) a PL/SQL record.
#
# This feature is new in cx_Oracle 5.3 and is only available in Oracle
# Database 12.1 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv
import datetime

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())

# create new object of the correct type
# note the use of a PL/SQL record defined in a package
# a table record identified by TABLE%ROWTYPE can also be used
typeObj = connection.gettype("PKG_DEMO.UDT_DEMORECORD")
obj = typeObj.newobject()
obj.NUMBERVALUE = 6
obj.STRINGVALUE = "Test String"
obj.DATEVALUE = datetime.datetime(2016, 5, 28)
obj.BOOLEANVALUE = False

# show the original values
print("NUMBERVALUE ->", obj.NUMBERVALUE)
print("STRINGVALUE ->", obj.STRINGVALUE)
print("DATEVALUE ->", obj.DATEVALUE)
print("BOOLEANVALUE ->", obj.BOOLEANVALUE)
print()

# call the stored procedure which will modify the object
cursor = connection.cursor()
cursor.callproc("pkg_Demo.DemoRecordsInOut", (obj,))

# show the modified values
print("NUMBERVALUE ->", obj.NUMBERVALUE)
print("STRINGVALUE ->", obj.STRINGVALUE)
print("DATEVALUE ->", obj.DATEVALUE)
print("BOOLEANVALUE ->", obj.BOOLEANVALUE)
print()

