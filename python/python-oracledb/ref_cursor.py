# -----------------------------------------------------------------------------
# Copyright (c) 2018, 2023, Oracle and/or its affiliates.
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
# ref_cursor.py
#
# Demonstrates the use of REF CURSORS.
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
)

with connection.cursor() as cursor:
    ref_cursor = connection.cursor()
    cursor.callproc("myrefcursorproc", (2, 6, ref_cursor))
    print("Rows between 2 and 6:")
    for row in ref_cursor:
        print(row)
    print()

    ref_cursor = connection.cursor()
    cursor.callproc("myrefcursorproc", (8, 9, ref_cursor))
    print("Rows between 8 and 9:")
    for row in ref_cursor:
        print(row)
    print()

    # -------------------------------------------------------------------------
    # Setting prefetchrows and arraysize of a REF CURSOR can improve
    # performance when fetching a large number of rows by reducing network
    # round-trips.
    # -------------------------------------------------------------------------

    # Truncate the table used for this demo
    cursor.execute("truncate table TestTempTable")

    # Populate the table with a large number of rows
    num_rows = 50000
    sql = "insert into TestTempTable (IntCol) values (:1)"
    data = [(n + 1,) for n in range(num_rows)]
    cursor.executemany(sql, data)

    # Perform an untuned fetch
    ref_cursor = connection.cursor()

    print(
        "ref_cursor.prefetchrows =",
        ref_cursor.prefetchrows,
        "ref_cursor.arraysize =",
        ref_cursor.arraysize,
    )
    start = time.time()
    sum_rows = 0
    cursor.callproc("myrefcursorproc2", [ref_cursor])
    for row in ref_cursor:
        sum_rows += row[0]
    elapsed = time.time() - start
    print(
        "Sum of IntCol for",
        num_rows,
        "rows is ",
        sum_rows,
        "in",
        elapsed,
        "seconds",
    )
    print()

    # Repeat the call but increase the internal arraysize and prefetch row
    # buffers for the REF CURSOR to tune the number of round-trips to the
    # database
    ref_cursor = connection.cursor()
    ref_cursor.prefetchrows = 1000
    ref_cursor.arraysize = 1000

    print(
        "ref_cursor.prefetchrows =",
        ref_cursor.prefetchrows,
        "ref_cursor.arraysize =",
        ref_cursor.arraysize,
    )
    start = time.time()
    sum_rows = 0
    cursor.callproc("myrefcursorproc2", [ref_cursor])
    for row in ref_cursor:
        sum_rows += row[0]
    elapsed = time.time() - start
    print(
        "Sum of IntCol for",
        num_rows,
        "rows is ",
        sum_rows,
        "in",
        elapsed,
        "seconds",
    )
