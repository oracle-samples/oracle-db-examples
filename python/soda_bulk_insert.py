#------------------------------------------------------------------------------
# Copyright (c) 2019, 2022, Oracle and/or its affiliates.
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
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# soda_bulk_insert.py
#
# Demonstrates the use of SODA bulk insert.
#
# Oracle Client must be at 18.5 or higher.
# Oracle Database must be at 18.1 or higher.
# The user must have been granted the SODA_APP privilege.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(sample_env.get_main_connect_string())

# the general recommendation for simple SODA usage is to enable autocommit
connection.autocommit = True

# create the parent object for all SODA work
soda = connection.getSodaDatabase()

# drop the collection if it already exists in order to ensure that the sample
# runs smoothly each time
collection = soda.openCollection("SodaBulkInsert")
if collection is not None:
    collection.drop()

# Explicit metadata is used for maximum version portability.
# Refer to the documentation.
metadata = {
    "keyColumn": {
        "name": "ID"
    },
    "contentColumn": {
        "name": "JSON_DOCUMENT",
        "sqlType": "BLOB"
    },
    "versionColumn": {
        "name": "VERSION",
        "method": "UUID"
    },
    "lastModifiedColumn": {
        "name": "LAST_MODIFIED"
    },
    "creationTimeColumn": {
        "name": "CREATED_ON"
    }
}

# create a new (or open an existing) SODA collection
collection = soda.createCollection("SodaBulkInsert", metadata)

# remove all documents from the collection
collection.find().remove()

# define some documents that will be stored
in_docs = [
    dict(name="Sam", age=8),
    dict(name="George", age=46),
    dict(name="Bill", age=35),
    dict(name="Sally", age=43),
    dict(name="Jill", age=28),
    dict(name="Cynthia", age=12)
]

# perform bulk insert
result_docs = collection.insertManyAndGet(in_docs)
for doc in result_docs:
    print("Inserted SODA document with key", doc.key)
print()

# perform search of all persons under the age of 40
print("Persons under the age of 40:")
for doc in collection.find().filter({'age': {'$lt': 40}}).getDocuments():
    print(doc.getContent()["name"] + ",", "key", doc.key)
