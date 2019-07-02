#------------------------------------------------------------------------------
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# SodaBulkInsert.py
#   Demonstrates the use of SODA bulk insert.
#
# This script requires cx_Oracle 7.2 and higher.
# Oracle Client must be at 18.5 or higher.
# Oracle Database must be at 18.1 or higher.
# The user must have been granted the SODA_APP privilege.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())

# the general recommendation for simple SODA usage is to enable autocommit
connection.autocommit = True

# create the parent object for all SODA work
soda = connection.getSodaDatabase()

# create a new (or open an existing) SODA collection
collection = soda.createCollection("SodaBulkInsert")

# remove all documents from the collection
collection.find().remove()

# define some documents that will be stored
inDocs = [
    dict(name="Sam", age=8),
    dict(name="George", age=46),
    dict(name="Bill", age=35),
    dict(name="Sally", age=43),
    dict(name="Jill", age=28),
    dict(name="Cynthia", age=12)
]

# perform bulk insert
resultDocs = collection.insertManyAndGet(inDocs)
for doc in resultDocs:
    print("Inserted SODA document with key", doc.key)
print()

# perform search of all persons under the age of 40
print("Persons under the age of 40:")
for doc in collection.find().filter({'age': {'$lt': 40}}).getDocuments():
    print(doc.getContent()["name"] + ",", "key", doc.key)
