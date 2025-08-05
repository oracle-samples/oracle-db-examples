# -----------------------------------------------------------------------------
# Copyright (c) 2025, Oracle and/or its affiliates.
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
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# dataframe_insert.py
#
# Shows how executemany() can be used to insert a Pandas dataframe directly
# into Oracle Database. The same technique can be used with data frames from
# many other libraries.
# -----------------------------------------------------------------------------

import sys
import pandas

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())


connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
    params=sample_env.get_connect_params(),
)

# -----------------------------------------------------------------------------
#
# Inserting a simple DataFrame

with connection.cursor() as cursor:

    # Create a Pandas DataFrame
    print("Pandas Dataframe 1:")
    d = {"A": [101, 213, 394], "B": ["Christie", "Cindy", "Kate"]}
    pdf = pandas.DataFrame(data=d)
    print(pdf)

    # Insert data into NUMBER and VARCHAR2(20) columns using Oracle Database's
    # efficient "Array DML" method
    cursor.executemany("insert into mytab (id, data) values (:1, :2)", pdf)

    # Check data
    print("\nOracle Database Query:")
    cursor.execute("select * from mytab order by id")
    columns = [col.name for col in cursor.description]
    print(columns)
    for r in cursor:
        print(r)

# -----------------------------------------------------------------------------
#
# Inserting VECTORs

# The VECTOR example only works with Oracle Database 23.4 or later
if sample_env.get_server_version() < (23, 4):
    sys.exit("This example requires Oracle Database 23.4 or later.")

# The VECTOR example works with thin mode, or with thick mode using Oracle
# Client 23.4 or later
if not connection.thin and oracledb.clientversion()[:2] < (23, 4):
    sys.exit(
        "This example requires python-oracledb thin mode, or Oracle Client"
        " 23.4 or later"
    )

with connection.cursor() as cursor:

    # Create a Pandas DataFrame
    print("\nPandas Dataframe 2:")
    d = {"v": [[3.3, 1.32, 5.0], [2.2, 2.32, 2.0]]}
    pdf = pandas.DataFrame(data=d)
    print(pdf)

    # Insert data into a VECTOR column using Oracle Database's
    # efficient "Array DML" method
    cursor.executemany("insert into SampleVectorTab (v64) values (:1)", pdf)

    # Check data
    print("\nOracle Database Query:")
    cursor.execute("select v64 from SampleVectorTab order by id")
    for (r,) in cursor:
        print(r)
