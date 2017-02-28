#------------------------------------------------------------------------------
# QueryChangeNotification.py
#   This script demonstrates using query change notification in Python, a
# feature that is available in Oracle 11g. Once this script is running, use
# another session to insert, update or delete rows from the table
# cx_Oracle.TestTempTable and you will see the notification of that change.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import threading
import time

def callback(message):
    print("Message type:", message.type)
    print("Message database name:", message.dbname)
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

connection = cx_Oracle.Connection("cx_Oracle/dev@localhost/orcl",
        events = True)
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

while True:
    print("Waiting for notifications....")
    time.sleep(5)

