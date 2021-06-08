#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# rows_as_instance.py
#   Returns rows as instances instead of tuples. See the ceDatabase.Row class
# in the cx_PyGenLib project (http://cx-pygenlib.sourceforge.net) for a more
# advanced example.
#
# This script requires cx_Oracle 4.3 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

class Test:

    def __init__(self, a, b, c):
        self.a = a
        self.b = b
        self.c = c

connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()

# change this to False if you want to create the table yourself using SQL*Plus
# and then populate it with the data of your choice
if True:
    cursor.execute("""
            select count(*)
            from user_tables
            where table_name = 'TESTINSTANCES'""")
    count, = cursor.fetchone()
    if count:
        cursor.execute("drop table TestInstances")
    cursor.execute("""
            create table TestInstances (
              a varchar2(60) not null,
              b number(9) not null,
              c date not null
            )""")
    cursor.execute("insert into TestInstances values ('First', 5, sysdate)")
    cursor.execute("insert into TestInstances values ('Second', 25, sysdate)")
    connection.commit()

# retrieve the data and display it
cursor.execute("select * from TestInstances")
cursor.rowfactory = Test
print("Rows:")
for row in cursor:
    print("a = %s, b = %s, c = %s" % (row.a, row.b, row.c))
