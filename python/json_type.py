#------------------------------------------------------------------------------
# Copyright (c) 2022, Oracle and/or its affiliates.
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
# json_type.py
#
# Demonstrates storing and fetching the JSON data into/from a Oracle Database
# 21c JSON type column.
#
# In order to use the JSON type in python-oracledb thin mode a type handler is
# needed to fetch the 21c JSON datatype.
#
# Note: The type handler is not needed when using python-oracledb thick mode
#       and Oracle Client 21.1 or higher. However, if a type handler is used
#       the behavior is the same in python-oracledb thin and thick modes.
#
# This script requires Oracle Database 21.1 or higher.
#------------------------------------------------------------------------------

import json
import sys

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

conn = oracledb.connect(sample_env.get_main_connect_string())
if not conn.thin:
    client_version = oracledb.clientversion()[0]
db_version = int(conn.version.split(".")[0])

# Minimum database vesion is 21
if db_version < 21:
    sys.exit("This example requires Oracle Database 21.1 or later.")

def type_handler(cursor, name, default_type, size, precision, scale):
    # to fetch the 21c JSON datatype when using python-oracledb thin mode
    if default_type == oracledb.DB_TYPE_JSON:
        return cursor.var(str, arraysize=cursor.arraysize,
                          outconverter=json.loads)
    # if using Oracle Client version < 21, then the database returns the
    # BLOB data type instead of the JSON data type
    elif default_type == oracledb.DB_TYPE_BLOB:
        return cursor.var(default_type, arraysize=cursor.arraysize,
                          outconverter=lambda v: json.loads(v.read()))

cursor = conn.cursor()

# Insert JSON data into a JSON column

data = [
    (1, dict(name="Rod", dept="Sales", location="Germany")),
    (2, dict(name="George", dept="Marketing", location="Bangalore")),
    (3, dict(name="Sam", dept="Sales", location="Mumbai")),
    (4, dict(name="Jill", dept="Marketing", location="Germany"))
]
insert_sql = "insert into CustomersAsJson values (:1, :2)"
if not conn.thin and client_version >= 21:
    # Take advantage of direct binding
    cursor.setinputsizes(None, oracledb.DB_TYPE_JSON)
    cursor.executemany(insert_sql, data)
else:
    # Insert the data as a JSON string
    cursor.executemany(insert_sql, [(i, json.dumps(j)) for i, j in data])

# Select JSON data from a JSON column

if conn.thin or client_version <  21:
    cursor.outputtypehandler = type_handler

for row in cursor.execute("select * from CustomersAsJson"):
    print(row)
