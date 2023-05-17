#------------------------------------------------------------------------------
# Copyright (c) 2020, 2022, Oracle and/or its affiliates.
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
#
# Note: To use the JSON type in python-oracledb thin mode see json_type.py
#------------------------------------------------------------------------------

import json
import sys

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(sample_env.get_main_connect_string())
client_version = oracledb.clientversion()[0]
db_version = int(connection.version.split(".")[0])

# this script only works with Oracle Database 21

if db_version < 21:
    sys.exit("This example requires Oracle Database 21.1 or later. "
             "Try json_blob.py")

cursor = connection.cursor()

# Insert JSON data

data = dict(name="Rod", dept="Sales", location="Germany")
inssql = "insert into CustomersAsJson values (:1, :2)"
if client_version >= 21:
    # Take advantage of direct binding
    cursor.setinputsizes(None, oracledb.DB_TYPE_JSON)
    cursor.execute(inssql, [1, data])
else:
    # Insert the data as a JSON string
    cursor.execute(inssql, [1, json.dumps(data)])

# Select JSON data

sql = "SELECT c.json_data FROM CustomersAsJson c"
if client_version >= 21:
    for j, in cursor.execute(sql):
        print(j)
else:
    for j, in cursor.execute(sql):
        print(json.loads(j.read()))

# Using JSON_VALUE to extract a value from a JSON column

sql = """SELECT JSON_VALUE(json_data, '$.location')
         FROM CustomersAsJson
         OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY"""
for r in cursor.execute(sql):
    print(r)

# Using dot-notation to extract a value from a JSON column

sql = """SELECT c.json_data.location
         FROM CustomersAsJson c
         OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY"""
if client_version >= 21:
    for j, in cursor.execute(sql):
        print(j)
else:
    for j, in cursor.execute(sql):
        print(json.loads(j.read()))

# Using JSON_OBJECT to extract relational data as JSON

sql = """SELECT JSON_OBJECT('key' IS d.dummy) dummy
         FROM dual d"""
for r in cursor.execute(sql):
    print(r)
