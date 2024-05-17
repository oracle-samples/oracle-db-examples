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
# query_strings_as_bytes_async.py
#
# An asynchronous version of query_strings_as_bytes.py
#
# Demonstrates how to query strings as bytes (bypassing decoding of the bytes
# into a Python string). This can be useful when attempting to fetch data that
# was stored in the database in the wrong encoding.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env

STRING_VAL = "I bought a cafetière on the Champs-Élysées"


def return_strings_as_bytes(cursor, metadata):
    if metadata.type_code is oracledb.DB_TYPE_VARCHAR:
        return cursor.var(str, arraysize=cursor.arraysize, bypass_decode=True)


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
    )

    # truncate table and populate with our data of choice
    with connection.cursor() as cursor:
        await cursor.execute("truncate table TestTempTable")
        await cursor.execute(
            "insert into TestTempTable values (1, :val)", val=STRING_VAL
        )
        await connection.commit()

    # fetch the data normally and show that it is returned as a string
    with connection.cursor() as cursor:
        await cursor.execute("select IntCol, StringCol from TestTempTable")
        print("Data fetched using normal technique:")
        async for row in cursor:
            print(row)
        print()

    # fetch the data, bypassing the decode and show that it is returned as
    # bytes
    with connection.cursor() as cursor:
        cursor.outputtypehandler = return_strings_as_bytes
        await cursor.execute("select IntCol, StringCol from TestTempTable")
        print("Data fetched using bypass decode technique:")
        async for row in cursor:
            print(row)


asyncio.run(main())
