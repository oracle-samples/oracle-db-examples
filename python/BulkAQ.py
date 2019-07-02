#------------------------------------------------------------------------------
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# BulkAQ.py
#   This script demonstrates how to use bulk enqueuing and dequeuing of
# messages with advanced queuing using cx_Oracle. It makes use of a RAW queue
# created in the sample setup.
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
    "The fourth message",
    "The fifth message",
    "The sixth message",
    "The seventh message",
    "The eighth message",
    "The ninth message",
    "The tenth message",
    "The eleventh message",
    "The twelfth and final message"
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
batchSize = 6
dataToEnq = PAYLOAD_DATA
while dataToEnq:
    batchData = dataToEnq[:batchSize]
    dataToEnq = dataToEnq[batchSize:]
    messages = [connection.msgproperties(payload=d) for d in batchData]
    for data in batchData:
        print(data)
    queue.enqMany(messages)
connection.commit()

# dequeue the messages
print("\nDequeuing messages...")
batchSize = 8
while True:
    messages = queue.deqMany(batchSize)
    if not messages:
        break
    for props in messages:
        print(props.payload.decode())
connection.commit()
print("\nDone.")
