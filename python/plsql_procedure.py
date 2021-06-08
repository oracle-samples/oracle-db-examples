#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# plsql_procedure.py
#
# Demonstrate how to call a PL/SQL stored procedure and get the results of an
# OUT variable.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

cursor = connection.cursor()
myvar = cursor.var(int)
cursor.callproc('myproc', (123, myvar))
print(myvar.getvalue())
