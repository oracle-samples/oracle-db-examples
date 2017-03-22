#------------------------------------------------------------------------------
# Copyright 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Editioning.py
#   This script demonstrates the use of editioning, available in Oracle
# Database 11.2 and higher. See the Oracle documentation on the subject for
# additional information. Adjust the contants at the top of the script for
# your own database as needed.
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

# define constants used throughout the script; adjust as desired
USER_NAME = "CX_ORACLE_TESTEDITIONS"
PASSWORD = "dev"
DBA_USER_NAME = "system"
DBA_PASSWORD = ""
DSN = ""
EDITION_NAME = "CX_ORACLE_E1"

# create user dropping it first, if necessary
connection = cx_Oracle.Connection(DBA_USER_NAME, DBA_PASSWORD, DSN)
cursor = connection.cursor()
cursor.execute("""
        select username
        from dba_users
        where username = :name""",
        name = USER_NAME)
names = [n for n, in cursor]
for name in names:
    print("Dropping user", name)
    cursor.execute("drop user %s cascade" % name)
print("Creating user", USER_NAME)
cursor.execute("create user %s identified by %s" % (USER_NAME, PASSWORD))
cursor.execute("grant create session, create procedure to %s" % USER_NAME)
cursor.execute("alter user %s enable editions" % USER_NAME)

# create edition, dropping it first, if necessary
cursor.execute("""
        select edition_name
        from dba_editions
        where edition_name = :name""",
        name = EDITION_NAME)
names = [n for n, in cursor]
for name in names:
    print("Dropping edition", name)
    cursor.execute("drop edition %s" % name)
print("Creating edition", EDITION_NAME)
cursor.execute("create edition %s" % EDITION_NAME)
cursor.execute("grant use on edition %s to %s" % (EDITION_NAME, USER_NAME))

# now connect to the newly created user and create a procedure
connection = cx_Oracle.Connection(USER_NAME, PASSWORD, DSN)
print("Edition should be None at this point, actual value is",
        connection.edition)
cursor = connection.cursor()
cursor.execute("""
        create or replace function TestEditions return varchar2 as
        begin
            return 'Base Edition';
        end;""")
result = cursor.callfunc("TestEditions", str)
print("Function call should return Base Edition, actually returns", result)

# next, change the edition and recreate the procedure in the new edition
cursor.execute("alter session set edition = %s" % EDITION_NAME)
print("Edition should be %s at this point, actual value is" % EDITION_NAME,
        connection.edition)
cursor.execute("""
        create or replace function TestEditions return varchar2 as
        begin
            return 'Edition 1';
        end;""")
result = cursor.callfunc("TestEditions", str)
print("Function call should return Edition 1, actually returns", result)

# next, change the edition back to the base edition and demonstrate that the
# original function is being called
cursor.execute("alter session set edition = ORA$BASE")
result = cursor.callfunc("TestEditions", str)
print("Function call should return Base Edition, actually returns", result)

# the edition can be set upon connection
connection = cx_Oracle.Connection(USER_NAME, PASSWORD, DSN,
        edition = EDITION_NAME)
cursor = connection.cursor()
result = cursor.callfunc("TestEditions", str)
print("Function call should return Edition 1, actually returns", result)

# it can also be set via the environment variable ORA_EDITION
os.environ["ORA_EDITION"] = EDITION_NAME
connection = cx_Oracle.Connection(USER_NAME, PASSWORD, DSN)
print("Edition should be %s at this point, actual value is" % EDITION_NAME,
        connection.edition)
cursor = connection.cursor()
result = cursor.callfunc("TestEditions", str)
print("Function call should return Edition 1, actually returns", result)

