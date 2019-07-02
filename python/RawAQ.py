#------------------------------------------------------------------------------
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# RawAQ.py
#   This script demonstrates how to use advanced queuing with RAW data using
# cx_Oracle. It makes use of a RAW queue created in the sample setup.
#
# This script requires cx_Oracle 7.2 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

QUEUE_NAME = "DEMO_RAW_QUEUE"
PAYLOAD_DATA = [
    "The first message",
    "The second message",
    "The third message",
    "The fourth and final message"
]

# connect to database
connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
cursor = connection.cursor()

# create queue
queue = connection.queue(QUEUE_NAME)
queue.deqOptions.wait = cx_Oracle.DEQ_NO_WAIT
queue.deqOptions.navigation = cx_Oracle.DEQ_FIRST_MSG

# dequeue all existing messages to ensure the queue is empty, just so that
# the results are consistent
while queue.deqOne():
    pass

# enqueue a few messages
print("Enqueuing messages...")
for data in PAYLOAD_DATA:
    print(data)
    queue.enqOne(connection.msgproperties(payload=data))
connection.commit()

# dequeue the messages
print("\nDequeuing messages...")
while True:
    props = queue.deqOne()
    if not props:
        break
    print(props.payload.decode())
connection.commit()
print("\nDone.")
