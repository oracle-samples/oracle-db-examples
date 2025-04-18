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
# batch_errors_async.py
#
# An asynchronous version of batch_errors.py
#
# Demonstrates the use of the Oracle Database 12.1 feature that allows
# cursor.executemany() to complete successfully, even if errors take
# place during the execution of one or more of the individual
# executions. The parameter "batcherrors" must be set to True in the
# call to cursor.executemany() after which cursor.getbatcherrors() can
# be called, which will return a list of error objects.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_connect_params(),
    )

    with connection.cursor() as cursor:
        # retrieve the number of rows in the table
        await cursor.execute("select count(*) from ChildTable")
        (count,) = await cursor.fetchone()
        print("Number of rows in child table:", int(count))

        # define data to insert
        data_to_insert = [
            (1016, 10, "Child B of Parent 10"),
            (1017, 10, "Child C of Parent 10"),
            (1018, 20, "Child D of Parent 20"),
            (1018, 20, "Child D of Parent 20"),  # duplicate key
            (1019, 30, "Child C of Parent 30"),
            (1020, 30, "Child D of Parent 40"),
            (1021, 60, "Child A of Parent 60"),  # parent does not exist
            (1022, 40, "Child F of Parent 40"),
        ]
        print("Number of rows to insert:", len(data_to_insert))

        # old method: executemany() with data errors results in stoppage after
        # the first error takes place; the row count is updated to show how
        # many rows actually succeeded
        try:
            await cursor.executemany(
                "insert into ChildTable values (:1, :2, :3)", data_to_insert
            )
        except oracledb.DatabaseError as e:
            (error,) = e.args
            print("Failure with error:", error.message)
            print("Number of rows successfully inserted:", cursor.rowcount)

        # demonstrate that the row count is accurate
        await cursor.execute("select count(*) from ChildTable")
        (count,) = await cursor.fetchone()
        print("Number of rows in child table after failed insert:", int(count))

        # roll back so we can perform the same work using the new method
        await connection.rollback()

        # new method: executemany() with batch errors enabled (and array DML
        # row counts also enabled) results in no immediate error being raised
        await cursor.executemany(
            "insert into ChildTable values (:1, :2, :3)",
            data_to_insert,
            batcherrors=True,
            arraydmlrowcounts=True,
        )

        # display the errors that have taken place
        errors = cursor.getbatcherrors()
        print("Number of rows with bad values:", len(errors))
        for error in errors:
            print(
                "Error", error.message.rstrip(), "at row offset", error.offset
            )

        # arraydmlrowcounts also shows rows with invalid data: they have a row
        # count of 0; otherwise 1 is shown
        row_counts = cursor.getarraydmlrowcounts()
        print("Array DML row counts:", row_counts)

        # demonstrate that all of the rows without errors have been
        # successfully inserted
        await cursor.execute("select count(*) from ChildTable")
        (count,) = await cursor.fetchone()
        print(
            "Number of rows in child table after insert with batcherrors "
            "enabled:",
            int(count),
        )


asyncio.run(main())
