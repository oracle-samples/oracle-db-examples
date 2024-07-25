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
# json_duality.py
#
# Demonstrates Oracle Database 23ai JSON-Relational Duality Views.
#
# Also see soda_json_duality.py
#
# Reference: https://www.oracle.com/pls/topic/lookup?ctx=dblatest&id=ADJSN
# -----------------------------------------------------------------------------

import json
import sys

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
)

if not connection.thin:
    client_version = oracledb.clientversion()[0]
db_version = int(connection.version.split(".")[0])

# this script only works with Oracle Database 23ai
if db_version < 23:
    sys.exit("This example requires Oracle Database 23 or later. ")

with connection.cursor() as cursor:

    # Create a JSON-Relational Duality View over the SampleJRDVAuthorTab and
    # SampleJRDVBookTab tables
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
    cursor.execute(sql)

with connection.cursor() as cursor:

    # Insert a new book and author into the Duality View and show the resulting
    # new records in the relational tables
    data = dict(
        _id=101,
        book_title="Cooking at Home",
        author=dict(author_id=201, author_name="Dave Smith"),
    )
    inssql = "insert into BookDV values (:1)"
    if connection.thin or client_version >= 21:
        # Take advantage of direct binding
        cursor.setinputsizes(oracledb.DB_TYPE_JSON)
        cursor.execute(inssql, [data])
    else:
        # Insert the data as a JSON string
        cursor.execute(inssql, [json.dumps(data)])

    print("Authors in the relational table:")
    for row in cursor.execute(
        "select * from SampleJRDVAuthorTab order by AuthorId"
    ):
        print(row)

    print("\nBooks in the relational table:")
    for row in cursor.execute(
        "select * from SampleJRDVBookTab order by BookId"
    ):
        print(row)

# Select from the duality view

with connection.cursor() as cursor:

    print("\nDuality view query for an author's books:")
    sql = """select b.data.book_title, b.data.author.author_name
             from BookDV b
             where b.data.author.author_id = :1"""
    for r in cursor.execute(sql, [1]):
        print(r)

    print("\nDuality view query of all records:")
    sql = """select data from BookDV"""
    if connection.thin or client_version >= 21:
        for (j,) in cursor.execute(sql):
            print(j)
    else:
        for (j,) in cursor.execute(sql):
            print(json.loads(j.read()))
