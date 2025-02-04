# -----------------------------------------------------------------------------
# Copyright (c) 2019, 2024, Oracle and/or its affiliates.
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
# last_rowid.py
#
# Demonstrates the use of the cursor.lastrowid attribute.
# -----------------------------------------------------------------------------

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

with connection.cursor() as cursor:
    # insert a couple of rows and retain the rowid of each
    row1 = [1, "First"]
    row2 = [2, "Second"]

    cursor.execute("insert into mytab (id, data) values (:1, :2)", row1)
    rowid1 = cursor.lastrowid
    print("Row 1:", row1)
    print("Rowid 1:", rowid1)
    print()

    cursor.execute("insert into mytab (id, data) values (:1, :2)", row2)
    rowid2 = cursor.lastrowid
    print("Row 2:", row2)
    print("Rowid 2:", rowid2)
    print()

    # the row can be fetched with the rowid that was returned
    cursor.execute("select id, data from mytab where rowid = :1", [rowid1])
    print("Row 1:", cursor.fetchone())
    cursor.execute("select id, data from mytab where rowid = :1", [rowid2])
    print("Row 2:", cursor.fetchone())
    print()

    # updating multiple rows only returns the rowid of the last updated row
    cursor.execute("update mytab set data = data || ' (Modified)'")
    cursor.execute(
        "select id, data from mytab where rowid = :1", [cursor.lastrowid]
    )
    print("Last updated row:", cursor.fetchone())

    # deleting multiple rows only returns the rowid of the last deleted row
    cursor.execute("delete from mytab")
    print("Rowid of last deleted row:", cursor.lastrowid)

    # deleting no rows results in a value of None
    cursor.execute("delete from mytab")
    print("Rowid when no rows are deleted:", cursor.lastrowid)

    # Don't commit - this lets us run the demo multiple times
    # connection.commit()
