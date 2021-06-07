#------------------------------------------------------------------------------
# Copyright (c) 2018, 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# AdvancedQueuingNotification.py
#   This script demonstrates using advanced queuing notification. Once this
# script is running, use another session to enqueue a few messages to the
# "DEMO_BOOK_QUEUE" queue. This is most easily accomplished by running the
# ObjectAQ.py sample.
#
# This script requires cx_Oracle 6.4 and higher.
#------------------------------------------------------------------------------

import cx_Oracle
import SampleEnv
import threading
import time

registered = True

def ProcessMessages(message):
    global registered
    print("Message type:", message.type)
    if message.type == cx_Oracle.EVENT_DEREG:
        print("Deregistration has taken place...")
        registered = False
        return
    print("Queue name:", message.queueName)
    print("Consumer name:", message.consumerName)

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString(), events = True)
sub = connection.subscribe(namespace=cx_Oracle.SUBSCR_NAMESPACE_AQ,
        name="DEMO_BOOK_QUEUE", callback=ProcessMessages, timeout=300)
print("Subscription:", sub)
print("--> Connection:", sub.connection)
print("--> Callback:", sub.callback)
print("--> Namespace:", sub.namespace)
print("--> Protocol:", sub.protocol)
print("--> Timeout:", sub.timeout)

while registered:
    print("Waiting for notifications....")
    time.sleep(5)

