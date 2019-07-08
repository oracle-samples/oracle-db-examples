#------------------------------------------------------------------------------
# Copyright (c) 2017, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ReturnNumbersAsDecimals.py
#   Returns all numbers as decimals by means of an output type handler. This is
# needed if the full decimal precision of Oracle numbers is required by the
# application. See this article
# (http://blog.reverberate.org/2016/02/06/floating-point-demystified-part2.html)
# for an explanation of why decimal numbers (like Oracle numbers) cannot be
# represented exactly by floating point numbers.
#
# This script requires cx_Oracle 5.0 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import decimal
import SampleEnv

def OutputTypeHandler(cursor, name, defaultType, size, precision, scale):
    if defaultType == cx_Oracle.NUMBER:
        return cursor.var(decimal.Decimal, arraysize = cursor.arraysize)

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
connection.outputtypehandler = OutputTypeHandler
cursor = connection.cursor()
cursor.execute("select * from TestNumbers")
for row in cursor:
    print("Row:", row)

