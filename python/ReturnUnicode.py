#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ReturnUnicode.py
#   Returns all strings as unicode. This also demonstrates the use of an output
# type handler to change the way in which data is returned from a cursor.
#
# This script requires cx_Oracle 5.0 and higher and will only work in Python 2.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

def OutputTypeHandler(cursor, name, defaultType, size, precision, scale):
    if defaultType in (cx_Oracle.STRING, cx_Oracle.FIXED_CHAR):
        return cursor.var(unicode, size, cursor.arraysize)

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
connection.outputtypehandler = OutputTypeHandler
cursor = connection.cursor()
cursor.execute("select * from TestStrings")
for row in cursor:
    print("Row:", row)

