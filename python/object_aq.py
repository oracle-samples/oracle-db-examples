#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# object_aq.py
#   This script demonstrates how to use advanced queuing with objects using
# cx_Oracle. It makes use of a simple type and queue created in the sample
# setup.
#
# This script requires cx_Oracle 8.2 and higher.
#------------------------------------------------------------------------------

import decimal

import cx_Oracle as oracledb
import sample_env

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
