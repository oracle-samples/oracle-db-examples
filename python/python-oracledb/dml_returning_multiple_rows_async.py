# -----------------------------------------------------------------------------
# Copyright (c) 2023, Oracle and/or its affiliates.
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
# dml_returning_multiple_rows_async.py
#
# An asynchronous version of dml_returning_multiple_rows.py
#
# Demonstrates the use of DML returning with multiple rows being returned at
# once.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
    )

    with connection.cursor() as cursor:
        # truncate table first so that script can be rerun
        print("Truncating table...")
        await cursor.execute("truncate table TestTempTable")

        # populate table with a few rows
        for i in range(5):
            data = (i + 1, "Test String #%d" % (i + 1))
            print("Adding row", data)
            await cursor.execute(
                "insert into TestTempTable values (:1, :2)", data
            )

        # now delete them and use DML returning to return the data that was
        # deleted
        int_col = cursor.var(int)
        string_col = cursor.var(str)
        print("Deleting data with DML returning...")
        await cursor.execute(
            """
            delete from TestTempTable
            returning IntCol, StringCol into :int_col, :string_col
            """,
            int_col=int_col,
            string_col=string_col,
        )
        print("Data returned:")
        for int_val, string_val in zip(
            int_col.getvalue(), string_col.getvalue()
        ):
            print(tuple([int_val, string_val]))


asyncio.run(main())
