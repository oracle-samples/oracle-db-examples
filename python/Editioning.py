#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Editioning.py
#   This script demonstrates the use of Edition-Based Redefinition, available
# in Oracle# Database 11.2 and higher. See the Oracle documentation on the
# subject for additional information. Adjust the contants at the top of the
# script for your own database as needed.
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv
import os

# connect to the editions user and create a procedure
editionConnectString = SampleEnv.GetEditionConnectString()
connection = cx_Oracle.connect(editionConnectString)
print("Edition should be None, actual value is:",
        repr(connection.edition))
cursor = connection.cursor()
cursor.execute("""
        create or replace function TestEditions return varchar2 as
        begin
            return 'Base Procedure';
        end;""")
result = cursor.callfunc("TestEditions", str)
print("Function should return 'Base Procedure', actually returns:",
        repr(result))

# next, change the edition and recreate the procedure in the new edition
cursor.execute("alter session set edition = %s" % SampleEnv.GetEditionName())
print("Edition should be", repr(SampleEnv.GetEditionName().upper()),
        "actual value is:", repr(connection.edition))
cursor.execute("""
        create or replace function TestEditions return varchar2 as
        begin
            return 'Edition 1 Procedure';
        end;""")
result = cursor.callfunc("TestEditions", str)
print("Function should return 'Edition 1 Procedure', actually returns:",
        repr(result))

# next, change the edition back to the base edition and demonstrate that the
# original function is being called
cursor.execute("alter session set edition = ORA$BASE")
result = cursor.callfunc("TestEditions", str)
print("Function should return 'Base Procedure', actually returns:",
        repr(result))

# the edition can be set upon connection
connection = cx_Oracle.connect(editionConnectString,
        edition = SampleEnv.GetEditionName().upper())
cursor = connection.cursor()
result = cursor.callfunc("TestEditions", str)
print("Function should return 'Edition 1 Procedure', actually returns:",
        repr(result))

# it can also be set via the environment variable ORA_EDITION
os.environ["ORA_EDITION"] = SampleEnv.GetEditionName().upper()
connection = cx_Oracle.connect(editionConnectString)
print("Edition should be", repr(SampleEnv.GetEditionName().upper()),
        "actual value is:", repr(connection.edition))
cursor = connection.cursor()
result = cursor.callfunc("TestEditions", str)
print("Function should return 'Edition 1 Procedure', actually returns:",
        repr(result))

