# -----------------------------------------------------------------------------
# Copyright (c) 2016, 2024, Oracle and/or its affiliates.
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
# query_arraysize.py
#
# Demonstrates how to alter the arraysize and prefetchrows values in order to
# tune the performance of fetching data from the database.  Increasing these
# values can reduce the number of network round trips and overhead required to
# fetch all of the rows from a large table.  The value affect internal buffers
# and do not affect how, or when, rows are returned to your application.
#
# The best values need to be determined by tuning in your production
# environment.
# -----------------------------------------------------------------------------

import time

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

# Global values can be set to override the defaults used when a cursor is
# created
#
# oracledb.defaults.prefetchrows = 200  # default is 2
# oracledb.defaults.arraysize = 200     # default is 100

with connection.cursor() as cursor:
    # Scenario 1: Selecting from a "large" table

    start = time.time()

    # Tune arraysize for your memory, network, and performance requirements.
    # Generally leave prefetchrows at its default of 2.
    cursor.arraysize = 1000

    cursor.execute("select * from bigtab")
    res = cursor.fetchall()

    elapsed = time.time() - start
    print("Prefetchrows:", cursor.prefetchrows, "Arraysize:", cursor.arraysize)
    print("Retrieved", len(res), "rows in", elapsed, "seconds")

    # Scenario 2: Selecting a "page" of data

    PAGE_SIZE = 20  # number of rows to fetch from the table

    start = time.time()

    cursor.arraysize = PAGE_SIZE
    cursor.prefetchrows = PAGE_SIZE + 1  # Set this one larger than arraysize
    # to remove an extra round-trip

    cursor.execute(
        "select * from bigtab offset 0 rows fetch next :r rows only",
        [PAGE_SIZE],
    )
    res = cursor.fetchall()

    elapsed = time.time() - start
    print("Prefetchrows:", cursor.prefetchrows, "Arraysize:", cursor.arraysize)
    print("Retrieved", len(res), "rows in", elapsed, "seconds")

    # Scenario 3: Selecting one row of data is similar to the previous example

    start = time.time()

    cursor.arraysize = 1
    cursor.prefetchrows = 2

    cursor.execute("select * from bigtab where rownum < 2")
    res = cursor.fetchall()

    elapsed = time.time() - start
    print("Prefetchrows:", cursor.prefetchrows, "Arraysize:", cursor.arraysize)
    print("Retrieved", len(res), "row in", elapsed, "seconds")
