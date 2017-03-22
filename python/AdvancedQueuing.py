#------------------------------------------------------------------------------
# Copyright 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# AdvancedQueuing.py
#   This script demonstrates how to use advanced queuing using cx_Oracle. It
# creates a simple type and enqueues and dequeues a few objects.
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

CONNECT_STRING = "cx_Oracle/dev@localhost/orcl"
BOOK_TYPE_NAME = "UDT_BOOK"
QUEUE_NAME = "BOOKS"
QUEUE_TABLE_NAME = "BOOK_QUEUE"

import cx_Oracle
import decimal

# connect to database
connection = cx_Oracle.Connection(CONNECT_STRING)
cursor = connection.cursor()

# drop queue table, if present
cursor.execute("""
        select count(*)
        from user_tables
        where table_name = :name""", name = QUEUE_TABLE_NAME)
count, = cursor.fetchone()
if count > 0:
    print("Dropping queue table...")
    cursor.callproc("dbms_aqadm.drop_queue_table", (QUEUE_TABLE_NAME, True))

# drop type, if present
cursor.execute("""
        select count(*)
        from user_types
        where type_name = :name""", name = BOOK_TYPE_NAME)
count, = cursor.fetchone()
if count > 0:
    print("Dropping books type...")
    cursor.execute("drop type %s" % BOOK_TYPE_NAME)

# create type
print("Creating books type...")
cursor.execute("""
        create type %s as object (
            title varchar2(100),
            authors varchar2(100),
            price number(5,2)
        );""" % BOOK_TYPE_NAME)

# create queue table and quueue and start the queue
print("Creating queue table...")
cursor.callproc("dbms_aqadm.create_queue_table",
        (QUEUE_TABLE_NAME, BOOK_TYPE_NAME))
cursor.callproc("dbms_aqadm.create_queue", (QUEUE_NAME, QUEUE_TABLE_NAME))
cursor.callproc("dbms_aqadm.start_queue", (QUEUE_NAME,))

# enqueue a few messages
booksType = connection.gettype(BOOK_TYPE_NAME)
book1 = booksType.newobject()
book1.TITLE = "The Fellowship of the Ring"
book1.AUTHORS = "Tolkien, J.R.R."
book1.PRICE = decimal.Decimal("10.99")
book2 = booksType.newobject()
book2.TITLE = "Harry Potter and the Philosopher's Stone"
book2.AUTHORS = "Rowling, J.K."
book2.PRICE = decimal.Decimal("7.99")
options = connection.enqoptions()
messageProperties = connection.msgproperties()
for book in (book1, book2):
    print("Enqueuing book", book.TITLE)
    connection.enq(QUEUE_NAME, options, messageProperties, book)
connection.commit()

# dequeue the messages
options = connection.deqoptions()
options.navigation = cx_Oracle.DEQ_FIRST_MSG
options.wait = cx_Oracle.DEQ_NO_WAIT
while connection.deq(QUEUE_NAME, options, messageProperties, book):
    print("Dequeued book", book.TITLE)

