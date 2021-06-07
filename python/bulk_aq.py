#------------------------------------------------------------------------------
# Copyright (c) 2019, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# bulk_aq.py
#   This script demonstrates how to use bulk enqueuing and dequeuing of
# messages with advanced queuing using cx_Oracle. It makes use of a RAW queue
# created in the sample setup.
#
# This script requires cx_Oracle 8.2 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

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
connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()

# create queue
queue = connection.queue(QUEUE_NAME)
queue.deqoptions.wait = oracledb.DEQ_NO_WAIT
queue.deqoptions.navigation = oracledb.DEQ_FIRST_MSG

# dequeue all existing messages to ensure the queue is empty, just so that
# the results are consistent
while queue.deqone():
    pass

# enqueue a few messages
print("Enqueuing messages...")
batch_size = 6
data_to_enqueue = PAYLOAD_DATA
while data_to_enqueue:
    batch_data = data_to_enqueue[:batch_size]
    data_to_enqueue = data_to_enqueue[batch_size:]
    messages = [connection.msgproperties(payload=d) for d in batch_data]
    for data in batch_data:
        print(data)
    queue.enqmany(messages)
connection.commit()

# dequeue the messages
print("\nDequeuing messages...")
batch_size = 8
while True:
    messages = queue.deqmany(batch_size)
    if not messages:
        break
    for props in messages:
        print(props.payload.decode())
connection.commit()
print("\nDone.")
