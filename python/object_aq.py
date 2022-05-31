#------------------------------------------------------------------------------
# Copyright (c) 2016, 2022, Oracle and/or its affiliates.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
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
# object_aq.py
#
# Demonstrates how to use advanced queuing with objects. It makes use of a
# simple type and queue created in the sample setup.
#------------------------------------------------------------------------------

import decimal

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

BOOK_TYPE_NAME = "UDT_BOOK"
QUEUE_NAME = "DEMO_BOOK_QUEUE"
BOOK_DATA = [
    ("The Fellowship of the Ring", "Tolkien, J.R.R.",
            decimal.Decimal("10.99")),
    ("Harry Potter and the Philosopher's Stone", "Rowling, J.K.",
            decimal.Decimal("7.99"))
]

# connect to database
connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()

# create queue
books_type = connection.gettype(BOOK_TYPE_NAME)
queue = connection.queue(QUEUE_NAME, payload_type=books_type)
queue.deqoptions.wait = oracledb.DEQ_NO_WAIT
queue.deqoptions.navigation = oracledb.DEQ_FIRST_MSG

# dequeue all existing messages to ensure the queue is empty, just so that
# the results are consistent
while queue.deqone():
    pass

# enqueue a few messages
print("Enqueuing messages...")
for title, authors, price in BOOK_DATA:
    book = books_type.newobject()
    book.TITLE = title
    book.AUTHORS = authors
    book.PRICE = price
    print(title)
    queue.enqone(connection.msgproperties(payload=book))
connection.commit()

# dequeue the messages
print("\nDequeuing messages...")
while True:
    props = queue.deqone()
    if not props:
        break
    print(props.payload.TITLE)
connection.commit()
print("\nDone.")
