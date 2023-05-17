# -----------------------------------------------------------------------------
# Copyright (c) 2021, 2022, Oracle and/or its affiliates.
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
# query_strings_as_bytes.py
#
# Demonstrates how to query strings as bytes (bypassing decoding of the bytes
# into a Python string). This can be useful when attempting to fetch data that
# was stored in the database in the wrong encoding.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

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
