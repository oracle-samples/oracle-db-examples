#------------------------------------------------------------------------------
# ReturnUnicode.py
#   Returns all strings as unicode. This also demonstrates the use of an output
# type handler to change the way in which data is returned from a cursor.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

def OutputTypeHandler(cursor, name, defaultType, size, precision, scale):
    if defaultType in (cx_Oracle.STRING, cx_Oracle.FIXED_CHAR):
        return cursor.var(unicode, size, cursor.arraysize)

connection = cx_Oracle.Connection("cx_Oracle/dev@localhost/orcl")
connection.outputtypehandler = OutputTypeHandler
cursor = connection.cursor()
cursor.execute("select * from teststrings")
for row in cursor:
    print("Row:", row)

