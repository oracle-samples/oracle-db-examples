#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# CQN.py
#   This script demonstrates using continuous query notification in Python, a
# feature that is available in Oracle 11g and later. Once this script is
# running, use another session to insert, update or delete rows from the table
# cx_Oracle.TestTempTable and you will see the notification of that change.
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv
import threading
import time

registered = True

def callback(message):
    global registered
    print("Message type:", message.type)
    if not message.registered:
        print("Deregistration has taken place...")
        registered = False
        return
    print("Message database name:", message.dbname)
    print("Message tranasction id:", message.txid)
    print("Message queries:")
    for query in message.queries:
        print("--> Query ID:", query.id)
        print("--> Query Operation:", query.operation)
        for table in query.tables:
            print("--> --> Table Name:", table.name)
            print("--> --> Table Operation:", table.operation)
            if table.rows is not None:
                print("--> --> Table Rows:")
                for row in table.rows:
                    print("--> --> --> Row RowId:", row.rowid)
                    print("--> --> --> Row Operation:", row.operation)
                    print("-" * 60)
            print("=" * 60)

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString(), events = True)
sub = connection.subscribe(callback = callback, timeout = 1800,
        qos = cx_Oracle.SUBSCR_QOS_QUERY | cx_Oracle.SUBSCR_QOS_ROWIDS)
print("Subscription:", sub)
print("--> Connection:", sub.connection)
print("--> Callback:", sub.callback)
print("--> Namespace:", sub.namespace)
print("--> Protocol:", sub.protocol)
print("--> Timeout:", sub.timeout)
print("--> Operations:", sub.operations)
print("--> Rowids?:", bool(sub.qos & cx_Oracle.SUBSCR_QOS_ROWIDS))
queryId = sub.registerquery("select * from TestTempTable")
print("Registered query:", queryId)

while registered:
    print("Waiting for notifications....")
    time.sleep(5)

