#------------------------------------------------------------------------------
# Copyright (c) 2016, 2022, Oracle and/or its affiliates.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#
# This software is dual-licensed to you under the Universal Permissive License
# (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
# 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
# either license.
#
# If you elect to accept the software under the Apache License, Version 2.0,
# the following applies:
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# rows_as_instance.py
#
# Returns rows as instances instead of tuples. See the ceDatabase.Row class
# in the cx_PyGenLib project (http://cx-pygenlib.sourceforge.net) for a more
# advanced example.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

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
