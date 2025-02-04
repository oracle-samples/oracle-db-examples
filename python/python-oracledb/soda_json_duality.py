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
# soda_json_duality.py
#
# An example of accessing Oracle Database 23ai JSON-Relational views using
# Simple Oracle Document Access (SODA).
#
# Oracle Client must be at 23.4 or higher.
# Oracle Database must be at 23.5 or higher.
# The user must have been granted the SODA_APP privilege.
#
# Also see json_duality.py
# -----------------------------------------------------------------------------

import sys
import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# this script only works with Oracle Database 23.5 & Client 23.4 or later
if sample_env.get_server_version() < (23, 5):
    sys.exit("This example requires Oracle Database 23.5 or later")
if oracledb.clientversion()[:2] < (23, 4):
    sys.exit("This example requires Oracle Client 23.4 or later")

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
)

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

# Create the parent object for SODA
soda = connection.getSodaDatabase()

# The duality view can be opened as if it were a collection
collection = soda.openCollection("BOOKDV")

# Count all documents
c = collection.find().count()
print("Collection has", c, "documents")

# Perform a query-by-example on the duality view
print("Books starting with 'The':")
qbe = {"book_title": {"$like": "The%"}}
for doc in collection.find().filter(qbe).getDocuments():
    content = doc.getContent()
    print(content["book_title"])

# Insert a document
content = {
    "_id": 201,
    "book_title": "Rainbows and Unicorns",
    "author": {"author_id": 401, "author_name": "Merlin"},
}
doc = collection.insertOneAndGet(content)
key = doc.key

# Fetch the document back and print the title
doc = collection.find().key(key).getOne()
content = doc.getContent()
print("Retrieved SODA document title is:")
print(content["book_title"])

# The new book can also be queried relationally from the base tables
print("Relational query:")
with connection.cursor() as cursor:
    sql = """
          select AuthorName, BookTitle
          from SampleJRDVAuthorTab, SampleJRDVBookTab
          where SampleJRDVAuthorTab.AuthorName = 'Merlin'
          and SampleJRDVAuthorTab.AuthorId = SampleJRDVBookTab.AuthorId"""

    for r in cursor.execute(sql):
        print(r)
