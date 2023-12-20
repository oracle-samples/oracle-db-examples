# -----------------------------------------------------------------------------
# Copyright (c) 2017, 2023, Oracle and/or its affiliates.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#
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
# universal_rowids.py
#
# Demonstrates the use of universal rowids. Universal rowids are used to
# identify rows in index organized tables.
# -----------------------------------------------------------------------------

import datetime

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

DATA = [
    (1, "String #1", datetime.datetime(2017, 4, 4)),
    (2, "String #2", datetime.datetime(2017, 4, 5)),
    (3, "A" * 250, datetime.datetime(2017, 4, 6)),
]

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
)

with connection.cursor() as cursor:
    # truncate table so sample can be rerun
    print("Truncating table...")
    cursor.execute("truncate table TestUniversalRowids")

    # populate table with a few rows
    print("Populating table...")
    for row in DATA:
        print("Inserting", row)
        cursor.execute(
            "insert into TestUniversalRowids values (:1, :2, :3)", row
        )
    connection.commit()

    # fetch the rowids from the table
    cursor.execute("select rowid from TestUniversalRowids")
    rowids = [r for r, in cursor]

    # fetch each of the rows given the rowid
    for rowid in rowids:
        print("-" * 79)
        print("Rowid:", rowid)
        cursor.execute(
            """
            select IntCol, StringCol, DateCol
            from TestUniversalRowids
            where rowid = :rid
            """,
            {"rid": rowid},
        )
        int_col, string_col, dateCol = cursor.fetchone()
        print("IntCol:", int_col)
        print("StringCol:", string_col)
        print("DateCol:", dateCol)
