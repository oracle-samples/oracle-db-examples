#------------------------------------------------------------------------------
# Copyright (c) 2018, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# soda_basic.py
#   A basic Simple Oracle Document Access (SODA) example.
#
# This script requires cx_Oracle 7.0 and higher.
# Oracle Client must be at 18.3 or higher.
# Oracle Database must be at 18.1 or higher.
# The user must have been granted the SODA_APP privilege.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

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

# Create a new SODA collection and index
# This will open an existing collection, if the name is already in use.
collection = soda.createCollection("mycollection", metadata)

index_spec = {
    'name': 'CITY_IDX',
    'fields': [
        {
            'path': 'address.city',
            'datatype': 'string',
            'order': 'asc'
        }
    ]
}
collection.createIndex(index_spec)

# Insert a document.
# A system generated key is created by default.
content = {'name': 'Matilda', 'address': {'city': 'Melbourne'}}
doc = collection.insertOneAndGet(content)
key = doc.key
print('The key of the new SODA document is: ', key)

# Fetch the document back
doc = collection.find().key(key).getOne() # A SodaDocument
content = doc.getContent()                # A JavaScript object
print('Retrieved SODA document dictionary is:')
print(content)
content = doc.getContentAsString()        # A JSON string
print('Retrieved SODA document string is:')
print(content)

# Replace document contents
content = {'name': 'Matilda', 'address': {'city': 'Sydney'}}
collection.find().key(key).replaceOne(content)

# Insert some more documents without caring about their keys
content = {'name': 'Venkat', 'address': {'city': 'Bengaluru'}}
collection.insertOne(content)
content = {'name': 'May', 'address': {'city': 'London'}}
collection.insertOne(content)
content = {'name': 'Sally-Ann', 'address': {'city': 'San Francisco'}}
collection.insertOne(content)

# Find all documents with names like 'Ma%'
print("Names matching 'Ma%'")
documents = collection.find().filter({'name': {'$like': 'Ma%'}}).getDocuments()
for d in documents:
    content = d.getContent()
    print(content["name"])

# Count all documents
c = collection.find().count()
print('Collection has', c, 'documents')

# Remove documents with cities containing 'o'
print('Removing documents')
c = collection.find().filter({'address.city': {'$regex': '.*o.*'}}).remove()
print('Dropped', c, 'documents')

# Count all documents
c = collection.find().count()
print('Collection has', c,  'documents')

# Drop the collection
if collection.drop():
    print('Collection was dropped')
