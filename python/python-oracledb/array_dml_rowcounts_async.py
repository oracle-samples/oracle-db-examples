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
# array_dml_rowcounts_async.py
#
# An asynchronous version of array_dml_rowcounts.py
#
# Demonstrates the use of the 12.1 feature that allows cursor.executemany()
# to return the number of rows affected by each individual execution as a list.
# The parameter "arraydmlrowcounts" must be set to True in the call to
# cursor.executemany() after which cursor.getarraydmlrowcounts() can be called.
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
        # show the number of rows for each parent ID as a means of verifying
        # the output from the delete statement
        await cursor.execute(
            """
            select ParentId, count(*)
            from ChildTable
            group by ParentId
            order by ParentId
            """
        )
        async for parent_id, count in cursor:
            print("Parent ID:", parent_id, "has", int(count), "rows.")
        print()

        # delete the following parent IDs only
        parent_ids_to_delete = [20, 30, 50]

        print("Deleting Parent IDs:", parent_ids_to_delete)
        print()

        # enable array DML row counts for each iteration executed in
        # executemany()
        await cursor.executemany(
            "delete from ChildTable where ParentId = :1",
            [(i,) for i in parent_ids_to_delete],
            arraydmlrowcounts=True,
        )

        # display the number of rows deleted for each parent ID
        row_counts = cursor.getarraydmlrowcounts()
        for parent_id, count in zip(parent_ids_to_delete, row_counts):
            print("Parent ID:", parent_id, "deleted", count, "rows.")


asyncio.run(main())
