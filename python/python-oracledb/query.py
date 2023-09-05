#------------------------------------------------------------------------------
# Copyright (c) 2016, 2023, Oracle and/or its affiliates.
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
# query.py
#
# Demonstrates different ways of fetching rows from a query.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(user=sample_env.get_main_user(),
                              password=sample_env.get_main_password(),
                              dsn=sample_env.get_connect_string())

sql = """select * from SampleQueryTab
         where id < 6
         order by id"""

with connection.cursor() as cursor:

    print("Get all rows via an iterator")
    for result in cursor.execute(sql):
        print(result)
    print()

    print("Query one row at a time")
    cursor.execute(sql)
    row = cursor.fetchone()
    print(row)
    row = cursor.fetchone()
    print(row)
    print()

    print("Fetch many rows")
    cursor.execute(sql)
    res = cursor.fetchmany(3)
    print(res)
    print()

    print("Fetch all rows")
    cursor.execute(sql)
    res = cursor.fetchall()
    print(res)
    print()

    print("Fetch each row as a Dictionary")
    cursor.execute(sql)
    columns = [col.name for col in cursor.description]
    cursor.rowfactory = lambda *args: dict(zip(columns, args))
    for row in cursor:
        print(row)
