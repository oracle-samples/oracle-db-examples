#------------------------------------------------------------------------------
# Copyright (c) 2016, 2022, Oracle and/or its affiliates.
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
# bind_insert.py
#
# Demonstrates how to insert a row into a table using bind variables.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(sample_env.get_main_connect_string())

#------------------------------------------------------------------------------
# "Bind by position"
#------------------------------------------------------------------------------

rows = [
    (1, "First"),
    (2, "Second"),
    (3, "Third"),
    (4, "Fourth"),
    (5, None),     # Insert a NULL value
    (6, "Sixth"),
    (7, "Seventh")
]

cursor = connection.cursor()

# predefine maximum string size to avoid data scans and memory reallocations;
# the None value indicates that the default processing can take place
cursor.setinputsizes(None, 20)

cursor.executemany("insert into mytab(id, data) values (:1, :2)", rows)

#------------------------------------------------------------------------------
# "Bind by name"
#------------------------------------------------------------------------------

rows = [
    {"d": "Eighth", "i": 8},
    {"d": "Ninth",  "i": 9},
    {"d": "Tenth",  "i": 10}
]

cursor = connection.cursor()

# Predefine maximum string size to avoid data scans and memory reallocations
cursor.setinputsizes(d=20)

cursor.executemany("insert into mytab(id, data) values (:i, :d)", rows)

#------------------------------------------------------------------------------
# Inserting a single bind still needs tuples
#------------------------------------------------------------------------------

rows = [
    ("Eleventh",),
    ("Twelth",)
]

cursor = connection.cursor()
cursor.executemany("insert into mytab(id, data) values (11, :1)", rows)

#------------------------------------------------------------------------------
# Now query the results back
#------------------------------------------------------------------------------

# Don't commit - this lets the demo be run multiple times
# connection.commit()

for row in cursor.execute('select * from mytab'):
    print(row)
