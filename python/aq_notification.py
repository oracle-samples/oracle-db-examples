#------------------------------------------------------------------------------
# Copyright (c) 2018, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# aq_notification.py
#   This script demonstrates using advanced queuing notification. Once this
# script is running, use another session to enqueue a few messages to the
# "DEMO_BOOK_QUEUE" queue. This is most easily accomplished by running the
# object_aq.py sample.
#
# This script requires cx_Oracle 6.4 and higher.
#------------------------------------------------------------------------------

import time

import cx_Oracle as oracledb
import sample_env

registered = True

def process_messages(message):
    global registered
    print("Message type:", message.type)
    if message.type == oracledb.EVENT_DEREG:
        print("Deregistration has taken place...")
        registered = False
        return
    print("Queue name:", message.queueName)
    print("Consumer name:", message.consumerName)

connection = oracledb.connect(sample_env.get_main_connect_string(),
                              events=True)
sub = connection.subscribe(namespace=oracledb.SUBSCR_NAMESPACE_AQ,
                           name="DEMO_BOOK_QUEUE", callback=process_messages,
                           timeout=300)
print("Subscription:", sub)
print("--> Connection:", sub.connection)
print("--> Callback:", sub.callback)
print("--> Namespace:", sub.namespace)
print("--> Protocol:", sub.protocol)
print("--> Timeout:", sub.timeout)

while registered:
    print("Waiting for notifications....")
    time.sleep(5)
