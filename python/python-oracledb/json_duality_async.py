# -----------------------------------------------------------------------------
# Copyright (c) 2024, Oracle and/or its affiliates.
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
# json_duality_async.py
#
# An asynchronous version of json_duality.py
#
# Demonstrates Oracle Database 23ai JSON-Relational Duality Views.
#
# Reference: https://www.oracle.com/pls/topic/lookup?ctx=dblatest&id=ADJSN
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

    # this script only works with Oracle Database 23.5 or later
    if sample_env.get_server_version() < (23, 5):
        sys.exit("This example requires Oracle Database 23.5 or later")

    with connection.cursor() as cursor:

        # Create a JSON-Relational Duality View over the SampleJRDVAuthorTab
        # and SampleJRDVBookTab tables
        sql = """
              create or replace json relational duality view BookDV as
              SampleJRDVBookTab @insert @update @delete
              {
                  _id: BookId,
                  book_title: BookTitle,
                  author: SampleJRDVAuthorTab @insert @update
                  {
                      author_id: AuthorId,
                      author_name: AuthorName
                  }
              }"""
        await cursor.execute(sql)

    with connection.cursor() as cursor:

        # Insert a new book and author into the Duality View and show the
        # resulting new records in the relational tables
        data = dict(
            _id=101,
            book_title="Cooking at Home",
            author=dict(author_id=201, author_name="Dave Smith"),
        )
        inssql = "insert into BookDV values (:1)"
        cursor.setinputsizes(oracledb.DB_TYPE_JSON)
        await cursor.execute(inssql, [data])

        print("Authors in the relational table:")
        await cursor.execute(
            "select * from SampleJRDVAuthorTab order by AuthorId"
        )
        async for row in cursor:
            print(row)

        print("\nBooks in the relational table:")
        await cursor.execute("select * from SampleJRDVBookTab order by BookId")
        async for row in cursor:
            print(row)

    # Select from the duality view

    with connection.cursor() as cursor:

        print("\nDuality view query for an author's books:")
        sql = """select b.data.book_title, b.data.author.author_name
                 from BookDV b
                 where b.data.author.author_id = :1"""
        await cursor.execute(sql, [1])
        async for r in cursor:
            print(r)

        print("\nDuality view query of all records:")
        sql = """select data from BookDV"""
        await cursor.execute(sql)
        async for (j,) in cursor:
            print(j)


asyncio.run(main())
