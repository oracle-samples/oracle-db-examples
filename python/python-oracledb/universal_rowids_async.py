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
# universal_rowids_async.py
#
# An asynchronous version of universal_rowids.py
#
# Demonstrates the use of universal rowids. Universal rowids are used to
# identify rows in index organized tables.
# -----------------------------------------------------------------------------

import asyncio
import datetime

import oracledb
import sample_env

DATA = [
    (1, "String #1", datetime.datetime(2017, 4, 4)),
    (2, "String #2", datetime.datetime(2017, 4, 5)),
    (3, "A" * 250, datetime.datetime(2017, 4, 6)),
]


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_connect_params(),
    )

    with connection.cursor() as cursor:
        # truncate table so sample can be rerun
        print("Truncating table...")
        await cursor.execute("truncate table TestUniversalRowids")

        # populate table with a few rows
        print("Populating table...")
        for row in DATA:
            print("Inserting", row)
            await cursor.execute(
                "insert into TestUniversalRowids values (:1, :2, :3)", row
            )
        await connection.commit()

        # fetch the rowids from the table
        await cursor.execute("select rowid from TestUniversalRowids")
        rowids = [r async for r, in cursor]

        # fetch each of the rows given the rowid
        for rowid in rowids:
            print("-" * 79)
            print("Rowid:", rowid)
            await cursor.execute(
                """
                select IntCol, StringCol, DateCol
                from TestUniversalRowids
                where rowid = :rid
                """,
                {"rid": rowid},
            )
            int_col, string_col, dateCol = await cursor.fetchone()
            print("IntCol:", int_col)
            print("StringCol:", string_col)
            print("DateCol:", dateCol)


asyncio.run(main())
