#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ObjectAQ.py
#   This script demonstrates how to use advanced queuing with objects using
# cx_Oracle. It makes use of a simple type and queue created in the sample
# setup.
#
# This script requires cx_Oracle 7.2 and higher.
#------------------------------------------------------------------------------

import cx_Oracle
import SampleEnv
import decimal

BOOK_TYPE_NAME = "UDT_BOOK"
QUEUE_NAME = "DEMO_BOOK_QUEUE"
BOOK_DATA = [
    ("The Fellowship of the Ring", "Tolkien, J.R.R.",
            decimal.Decimal("10.99")),
    ("Harry Potter and the Philosopher's Stone", "Rowling, J.K.",
            decimal.Decimal("7.99"))
]

# connect to database
connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
cursor = connection.cursor()

# create queue
booksType = connection.gettype(BOOK_TYPE_NAME)
queue = connection.queue(QUEUE_NAME, booksType)
queue.deqOptions.wait = cx_Oracle.DEQ_NO_WAIT
queue.deqOptions.navigation = cx_Oracle.DEQ_FIRST_MSG

# dequeue all existing messages to ensure the queue is empty, just so that
# the results are consistent
while queue.deqOne():
    pass

# enqueue a few messages
print("Enqueuing messages...")
for title, authors, price in BOOK_DATA:
    book = booksType.newobject()
    book.TITLE = title
    book.AUTHORS = authors
    book.PRICE = price
    print(title)
    queue.enqOne(connection.msgproperties(payload=book))
connection.commit()

# dequeue the messages
print("\nDequeuing messages...")
while True:
    props = queue.deqOne()
    if not props:
        break
    print(props.payload.TITLE)
connection.commit()
print("\nDone.")
