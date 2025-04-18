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
# json_direct_async.py
#
# An asynchronous version of json_direct.py
#
# Demonstrates the use of some JSON features with the JSON type that is
# available in Oracle Database 21c and higher.
#
# See https://www.oracle.com/pls/topic/lookup?ctx=dblatest&id=ADJSN
#
# For JSON with older databases see json_blob_async.py
# -----------------------------------------------------------------------------

import asyncio
import sys

import oracledb
import sample_env


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_connect_params(),
    )

    # this script only works with Oracle Database 21
    db_version = int(connection.version.split(".")[0])
    if db_version < 21:
        sys.exit(
            "This example requires Oracle Database 21.1 or later. "
            "Try json_blob.py instead"
        )

    # Insert JSON data
    with connection.cursor() as cursor:
        data = dict(name="Rod", dept="Sales", location="Germany")
        inssql = "insert into CustomersAsJson values (:1, :2)"
        cursor.setinputsizes(None, oracledb.DB_TYPE_JSON)
        await cursor.execute(inssql, [1, data])

    # Select JSON data
    with connection.cursor() as cursor:
        sql = "select c.json_data from CustomersAsJson c"
        await cursor.execute(sql)
        async for (j,) in cursor:
            print(j)

        # Using JSON_VALUE to extract a value from a JSON column

        sql = """select json_value(json_data, '$.location')
                 from CustomersAsJson
                 offset 0 rows fetch next 1 rows only"""
        await cursor.execute(sql)
        async for r in cursor:
            print(r)

        # Using dot-notation to extract a value from a JSON column

        sql = """select c.json_data.location
                 from CustomersAsJson c
                 offset 0 rows fetch next 1 rows only"""
        await cursor.execute(sql)
        async for (j,) in cursor:
            print(j)

        # Using JSON_OBJECT to extract relational data as JSON

        sql = """select json_object('key' is d.dummy) dummy
                 from dual d"""
        await cursor.execute(sql)
        async for r in cursor:
            print(r)

        # Using JSON_ARRAYAGG to extract a whole relational table as JSON

        oracledb.defaults.fetch_lobs = False
        sql = """select json_arrayagg(
                            json_object('key' is c.id,
                                        'name' is c.json_data)
                            returning clob)
                 from CustomersAsJson c"""
        await cursor.execute(sql)
        async for r in cursor:
            print(r)


asyncio.run(main())
