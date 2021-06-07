#------------------------------------------------------------------------------
# Copyright (c) 2020, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# multi_consumer_aq.py
#   This script demonstrates how to use multi-consumer advanced queuing using
# cx_Oracle. It makes use of a RAW queue created in the sample setup.
#
# This script requires cx_Oracle 8.2 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

QUEUE_NAME = "DEMO_RAW_QUEUE_MULTI"
PAYLOAD_DATA = [
    "The first message",
    "The second message",
    "The third message",
    "The fourth and final message"
]

# connect to database
connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()

# create queue
queue = connection.queue(QUEUE_NAME)
queue.deqoptions.wait = oracledb.DEQ_NO_WAIT
queue.deqoptions.navigation = oracledb.DEQ_FIRST_MSG

# enqueue a few messages
print("Enqueuing messages...")
for data in PAYLOAD_DATA:
    print(data)
    queue.enqone(connection.msgproperties(payload=data))
connection.commit()
print()

# dequeue the messages for consumer A
print("Dequeuing the messages for consumer A...")
queue.deqoptions.consumername = "SUBSCRIBER_A"
while True:
    props = queue.deqone()
    if not props:
        break
    print(props.payload.decode())
connection.commit()
print()

# dequeue the message for consumer B
print("Dequeuing the messages for consumer B...")
queue.deqoptions.consumername = "SUBSCRIBER_B"
while True:
    props = queue.deqone()
    if not props:
        break
    print(props.payload.decode())
connection.commit()

print("\nDone.")
