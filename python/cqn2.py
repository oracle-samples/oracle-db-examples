#------------------------------------------------------------------------------
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# CQN2.py
#   This script demonstrates using continuous query notification in Python, a
# feature that is available in Oracle 11g and later. Once this script is
# running, use another session to insert, update or delete rows from the table
# cx_Oracle.TestTempTable and you will see the notification of that change.
#
#   This script differs from CQN.py in that it shows how a connection can be
# acquired from a session pool and used to query the changes that have been
# made.
#
# This script requires cx_Oracle 7 or higher.
#------------------------------------------------------------------------------

import cx_Oracle
import SampleEnv
import time

registered = True

def callback(message):
    global registered
    if not message.registered:
        print("Deregistration has taken place...")
        registered = False
        return
    connection = pool.acquire()
    for query in message.queries:
        for table in query.tables:
            if table.rows is None:
                print("Too many row changes detected in table", table.name)
                continue
            numRowsDeleted = 0
            print(len(table.rows), "row changes detected in table", table.name)
            for row in table.rows:
                if row.operation & cx_Oracle.OPCODE_DELETE:
                    numRowsDeleted += 1
                    continue
                ops = []
                if row.operation & cx_Oracle.OPCODE_INSERT:
                    ops.append("inserted")
                if row.operation & cx_Oracle.OPCODE_UPDATE:
                    ops.append("updated")
                cursor = connection.cursor()
                cursor.execute("""
                        select IntCol
                        from TestTempTable
                        where rowid = :rid""",
                        rid=row.rowid)
                intCol, = cursor.fetchone()
                print("    Row with IntCol", intCol, "was", " and ".join(ops))
            if numRowsDeleted > 0:
                print("   ", numRowsDeleted, "rows deleted")
            print("=" * 60)

pool = cx_Oracle.SessionPool(SampleEnv.GetMainUser(),
        SampleEnv.GetMainPassword(), SampleEnv.GetConnectString(), min=2,
        max=5, increment=1, events=True, threaded=True)
with pool.acquire() as connection:
    sub = connection.subscribe(callback=callback, timeout=1800,
            qos=cx_Oracle.SUBSCR_QOS_QUERY | cx_Oracle.SUBSCR_QOS_ROWIDS)
    print("Subscription created with ID:", sub.id)
    queryId = sub.registerquery("select * from TestTempTable")
    print("Registered query with ID:", queryId)

while registered:
    print("Waiting for notifications....")
    time.sleep(5)
