#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# plsql_function.py
#
# Demonstrate how to call a PL/SQL function and get its return value.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

cursor = connection.cursor()
res = cursor.callfunc('myfunc', int, ('abc', 2))
print(res)
