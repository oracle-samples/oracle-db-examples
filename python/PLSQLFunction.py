#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# PLSQLFunction.py
#
# Demonstrate how to call a PL/SQL function and get its return value.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())

cursor = connection.cursor()
res = cursor.callfunc('myfunc', int, ('abc', 2))
print(res)

