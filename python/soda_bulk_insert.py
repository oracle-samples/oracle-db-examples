#------------------------------------------------------------------------------
# Copyright (c) 2019, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# soda_bulk_insert.py
#   Demonstrates the use of SODA bulk insert.
#
# This script requires cx_Oracle 7.2 and higher.
# Oracle Client must be at 18.5 or higher.
# Oracle Database must be at 18.1 or higher.
# The user must have been granted the SODA_APP privilege.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

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
