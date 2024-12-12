# -----------------------------------------------------------------------------
# Copyright (c) 2023, 2024, Oracle and/or its affiliates.
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
# vector_string.py
#
# Demonstrates how to use the Oracle Database 23ai VECTOR data type
# when using python-oracledb thick mode with pre-23ai Oracle Client libraries.
# See vector.py for a more efficient example for other deployments.
# -----------------------------------------------------------------------------

import sys
import oracledb
import sample_env

# Although the code in this example could run with python-oracledb thin mode,
# it is not efficient so it should only be used for thick mode with old Oracle
# Client libraries.
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
    params=sample_env.get_connect_params(),
)

# this script only works with Oracle Database 23.5 or later
if sample_env.get_server_version() < (23, 5):
    sys.exit("This example requires Oracle Database 23.5 or later.")


with connection.cursor() as cursor:
    # Single-row insert
    vector1_data_32 = "[1.625, 1.5, 1.0]"
    vector1_data_64 = "[11.25, 11.75, 11.5]"
    vector1_data_8 = "[1, 2, 3]"
    vector1_data_bin = "[180, 150, 100]"

    cursor.execute(
        """insert into SampleVectorTab (v32, v64, v8, vbin)
           values (:1, :2, :3, :4)""",
        [vector1_data_32, vector1_data_64, vector1_data_8, vector1_data_bin],
    )

    # Multi-row insert
    vector2_data_32 = "[2.625, 2.5, 2.0]"
    vector2_data_64 = "[22.25, 22.75, 22.5]"
    vector2_data_8 = "[4, 5, 6]"
    vector2_data_bin = "[40, 15, 255]"

    vector3_data_32 = "[3.625, 3.5, 3.0]"
    vector3_data_64 = "[33.25, 33.75, 33.5]"
    vector3_data_8 = "[7, 8, 9]"
    vector3_data_bin = "[0, 17, 101]"

    rows = [
        (vector2_data_32, vector2_data_64, vector2_data_8, vector2_data_bin),
        (vector3_data_32, vector3_data_64, vector3_data_8, vector3_data_bin),
    ]

    cursor.executemany(
        """insert into SampleVectorTab (v32, v64, v8, vbin)
                          values (:1, :2, :3, :4)""",
        rows,
    )

    # Query
    cursor.execute("select * from SampleVectorTab")

    # Each vector is represented as a list
    for row in cursor:
        print(row)
