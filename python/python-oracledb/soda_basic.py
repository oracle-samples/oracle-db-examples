# -----------------------------------------------------------------------------
# Copyright (c) 2018, 2023, Oracle and/or its affiliates.
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
# soda_basic.py
#
# A basic Simple Oracle Document Access (SODA) example.
#
# Oracle Client must be at 18.3 or higher.
# Oracle Database must be at 18.1 or higher.
# The user must have been granted the SODA_APP privilege.
# -----------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
)

# The general recommendation for simple SODA usage is to enable autocommit
connection.autocommit = True

# Create the parent object for SODA
soda = connection.getSodaDatabase()

# drop the collection if it already exists in order to ensure that the sample
# runs smoothly each time
collection = soda.openCollection("mycollection")
if collection is not None:
    collection.drop()

# Explicit metadata is used for maximum version portability.
# Refer to the documentation.
metadata = {
    "keyColumn": {"name": "ID"},
    "contentColumn": {"name": "JSON_DOCUMENT", "sqlType": "BLOB"},
    "versionColumn": {"name": "VERSION", "method": "UUID"},
    "lastModifiedColumn": {"name": "LAST_MODIFIED"},
    "creationTimeColumn": {"name": "CREATED_ON"},
}

# Create a new SODA collection and index
# This will open an existing collection, if the name is already in use.
collection = soda.createCollection("mycollection", metadata)

index_spec = {
    "name": "CITY_IDX",
    "fields": [{"path": "address.city", "datatype": "string", "order": "asc"}],
}
collection.createIndex(index_spec)

# Insert a document.
# A system generated key is created by default.
content = {"name": "Matilda", "address": {"city": "Melbourne"}}
doc = collection.insertOneAndGet(content)
key = doc.key
print("The key of the new SODA document is: ", key)

# Fetch the document back
doc = collection.find().key(key).getOne()  # A SodaDocument
content = doc.getContent()  # A JavaScript object
print("Retrieved SODA document dictionary is:")
print(content)
content = doc.getContentAsString()  # A JSON string
print("Retrieved SODA document string is:")
print(content)

# Replace document contents
content = {"name": "Matilda", "address": {"city": "Sydney"}}
collection.find().key(key).replaceOne(content)

# Insert some more documents without caring about their keys
content = {"name": "Venkat", "address": {"city": "Bengaluru"}}
collection.insertOne(content)
content = {"name": "May", "address": {"city": "London"}}
collection.insertOne(content)
content = {"name": "Sally-Ann", "address": {"city": "San Francisco"}}
collection.insertOne(content)

# Find all documents with names like 'Ma%'
print("Names matching 'Ma%'")
documents = collection.find().filter({"name": {"$like": "Ma%"}}).getDocuments()
for d in documents:
    content = d.getContent()
    print(content["name"])

# Count all documents
c = collection.find().count()
print("Collection has", c, "documents")

# Remove documents with cities containing 'o'
print("Removing documents")
c = collection.find().filter({"address.city": {"$regex": ".*o.*"}}).remove()
print("Dropped", c, "documents")

# Count all documents
c = collection.find().count()
print("Collection has", c, "documents")

# Drop the collection
if collection.drop():
    print("Collection was dropped")
