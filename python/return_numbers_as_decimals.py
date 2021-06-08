#------------------------------------------------------------------------------
# Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# return_numbers_as_decimals.py
#   Returns all numbers as decimals by means of an output type handler. This is
# needed if the full decimal precision of Oracle numbers is required by the
# application. See this article
# (http://blog.reverberate.org/2016/02/06/floating-point-demystified-part2.html)
# for an explanation of why decimal numbers (like Oracle numbers) cannot be
# represented exactly by floating point numbers.
#
# This script requires cx_Oracle 5.0 and higher.
#------------------------------------------------------------------------------

import decimal

import cx_Oracle as oracledb
import sample_env

def output_type_handler(cursor, name, default_type, size, precision, scale):
    if default_type == oracledb.NUMBER:
        return cursor.var(decimal.Decimal, arraysize=cursor.arraysize)

connection = oracledb.connect(sample_env.get_main_connect_string())
connection.outputtypehandler = output_type_handler
cursor = connection.cursor()
cursor.execute("select * from TestNumbers")
for row in cursor:
    print("Row:", row)
