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
# query_async.py
#
# An asynchronous version of query.py
#
# Demonstrates different ways of fetching rows from a query with asyncio.
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

    sql = """select * from SampleQueryTab
             where id < 6
             order by id"""

    with connection.cursor() as cursor:
        print("Get all rows via an iterator")
        await cursor.execute(sql)
        async for result in cursor:
            print(result)
        print()

        print("Query one row at a time")
        await cursor.execute(sql)
        row = await cursor.fetchone()
        print(row)
        row = await cursor.fetchone()
        print(row)
        print()

    print("Fetch many rows")
    res = await connection.fetchmany(sql, num_rows=3)
    print(res)
    print()

    print("Fetch all rows")
    res = await connection.fetchall(sql)
    print(res)
    print()

    with connection.cursor() as cursor:
        print("Fetch each row as a Dictionary")
        await cursor.execute(sql)
        columns = [col.name for col in cursor.description]
        cursor.rowfactory = lambda *args: dict(zip(columns, args))
        async for row in cursor:
            print(row)


asyncio.run(main())
