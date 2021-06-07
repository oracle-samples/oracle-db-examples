#------------------------------------------------------------------------------
# Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# query_strings_as_bytes.py
#
# Demonstrates how to query strings as bytes (bypassing decoding of the bytes
# into a Python string). This can be useful when attempting to fetch data that
# was stored in the database in the wrong encoding.
#
# This script requires cx_Oracle 8.2 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

STRING_VAL = 'I bought a cafetière on the Champs-Élysées'

def return_strings_as_bytes(cursor, name, default_type, size, precision,
                            scale):
    if default_type == oracledb.DB_TYPE_VARCHAR:
        return cursor.var(str, arraysize=cursor.arraysize, bypass_decode=True)

with oracledb.connect(sample_env.get_main_connect_string()) as conn:

    # truncate table and populate with our data of choice
    with conn.cursor() as cursor:
        cursor.execute("truncate table TestTempTable")
        cursor.execute("insert into TestTempTable values (1, :val)",
                       val=STRING_VAL)
        conn.commit()

    # fetch the data normally and show that it is returned as a string
    with conn.cursor() as cursor:
        cursor.execute("select IntCol, StringCol from TestTempTable")
        print("Data fetched using normal technique:")
        for row in cursor:
            print(row)
        print()

    # fetch the data, bypassing the decode and show that it is returned as
    # bytes
    with conn.cursor() as cursor:
        cursor.outputtypehandler = return_strings_as_bytes
        cursor.execute("select IntCol, StringCol from TestTempTable")
        print("Data fetched using bypass decode technique:")
        for row in cursor:
            print(row)
