#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Subclassing.py
#
# Demonstrate how to subclass cx_Oracle connections and cursors in order to
# add additional functionality (like logging) or create specialized interfaces
# for paticular applications.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

# sample subclassed connection which overrides the constructor (so no
# parameters are required) and the cursor() method (so that the subclassed
# cursor is returned instead of the default cursor implementation)
class Connection(cx_Oracle.Connection):

    def __init__(self):
        connectString = SampleEnv.GetMainConnectString()
        print("CONNECT to database")
        return super(Connection, self).__init__(connectString)

    def cursor(self):
        return Cursor(self)


# sample subclassed cursor which overrides the execute() and fetchone()
# methods in order to perform some simple logging
class Cursor(cx_Oracle.Cursor):

    def execute(self, statement, args):
        print("EXECUTE", statement)
        print("ARGS:")
        for argIndex, arg in enumerate(args):
            print("   ", argIndex + 1, "=>", repr(arg))
        return super(Cursor, self).execute(statement, args)

    def fetchone(self):
        print("FETCH ONE")
        return super(Cursor, self).fetchone()


# create instances of the subclassed connection and cursor
connection = Connection()
cursor = connection.cursor()

# demonstrate that the subclassed connection and cursor are being used
cursor.execute("select count(*) from ChildTable where ParentId = :1", (30,))
count, = cursor.fetchone()
print("COUNT:", int(count))

