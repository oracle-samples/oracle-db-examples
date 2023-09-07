#------------------------------------------------------------------------------
# Copyright (c) 2020, 2023, Oracle and/or its affiliates.
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
# json_direct.py
#
# Demonstrates the use of some JSON features with the JSON type that is
# available in Oracle Database 21c and higher.
#
# See https://www.oracle.com/pls/topic/lookup?ctx=dblatest&id=ADJSN
#
# For JSON with older databases see json_blob.py
#------------------------------------------------------------------------------

import json
import sys

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(user=sample_env.get_main_user(),
                              password=sample_env.get_main_password(),
                              dsn=sample_env.get_connect_string())

if not connection.thin:
    client_version = oracledb.clientversion()[0]
db_version = int(connection.version.split(".")[0])

# this script only works with Oracle Database 21
if db_version < 21:
    sys.exit("This example requires Oracle Database 21.1 or later. "
             "Try json_blob.py instead")

# Insert JSON data
with connection.cursor() as cursor:

    data = dict(name="Rod", dept="Sales", location="Germany")
    inssql = "insert into CustomersAsJson values (:1, :2)"
    if connection.thin or client_version >= 21:
        # Take advantage of direct binding
        cursor.setinputsizes(None, oracledb.DB_TYPE_JSON)
        cursor.execute(inssql, [1, data])
    else:
        # Insert the data as a JSON string
        cursor.execute(inssql, [1, json.dumps(data)])

# Select JSON data
with connection.cursor() as cursor:

    sql = "select c.json_data from CustomersAsJson c"
    if connection.thin or client_version >= 21:
        for j, in cursor.execute(sql):
            print(j)
    else:
        for j, in cursor.execute(sql):
            print(json.loads(j.read()))

    # Using JSON_VALUE to extract a value from a JSON column

    sql = """select json_value(json_data, '$.location')
             from CustomersAsJson
             offset 0 rows fetch next 1 rows only"""
    for r in cursor.execute(sql):
        print(r)

    # Using dot-notation to extract a value from a JSON column

    sql = """select c.json_data.location
             from CustomersAsJson c
             offset 0 rows fetch next 1 rows only"""
    if connection.thin or client_version >= 21:
        for j, in cursor.execute(sql):
            print(j)
    else:
        for j, in cursor.execute(sql):
            print(json.loads(j.read()))

    # Using JSON_OBJECT to extract relational data as JSON

    sql = """select json_object('key' is d.dummy) dummy
             from dual d"""
    for r in cursor.execute(sql):
        print(r)

    # Using JSON_ARRAYAGG to extract a whole relational table as JSON

    oracledb.defaults.fetch_lobs = False
    sql = """select json_arrayagg(
                        json_object('key' is c.id,
                                    'name' is c.json_data)
                        returning clob)
             from CustomersAsJson c"""
    for r in cursor.execute(sql):
        print(r)
