#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# GenericRowFactory.py
#
# Demonstrate the ability to return named tuples for all queries using a
# subclassed cursor and row factory.
#------------------------------------------------------------------------------

from __future__ import print_function

import collections
import cx_Oracle
import SampleEnv

class Connection(cx_Oracle.Connection):

    def cursor(self):
        return Cursor(self)


class Cursor(cx_Oracle.Cursor):

    def execute(self, statement, args = None):
        prepareNeeded = (self.statement != statement)
        result = super(Cursor, self).execute(statement, args or [])
        if prepareNeeded:
            description = self.description
            if description:
                names = [d[0] for d in description]
                self.rowfactory = collections.namedtuple("GenericQuery", names)
        return result


# create new subclassed connection and cursor
connection = Connection(SampleEnv.GetMainConnectString())
cursor = connection.cursor()

# the names are now available directly for each query executed
for row in cursor.execute("select ParentId, Description from ParentTable"):
    print(row.PARENTID, "->", row.DESCRIPTION)
print()

for row in cursor.execute("select ChildId, Description from ChildTable"):
    print(row.CHILDID, "->", row.DESCRIPTION)
print()

