#------------------------------------------------------------------------------
# Copyright (c) 2020, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# cqn2.py
#   This script demonstrates using continuous query notification in Python, a
# feature that is available in Oracle 11g and later. Once this script is
# running, use another session to insert, update or delete rows from the table
# TestTempTable and you will see the notification of that change.
#
#   This script differs from cqn.py in that it shows how a connection can be
# acquired from a session pool and used to query the changes that have been
# made.
#
# This script requires cx_Oracle 7 or higher.
#------------------------------------------------------------------------------

import time

import cx_Oracle as oracledb
import sample_env

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
            num_rows_deleted = 0
            print(len(table.rows), "row changes detected in table", table.name)
            for row in table.rows:
                if row.operation & oracledb.OPCODE_DELETE:
                    num_rows_deleted += 1
                    continue
                ops = []
                if row.operation & oracledb.OPCODE_INSERT:
                    ops.append("inserted")
                if row.operation & oracledb.OPCODE_UPDATE:
                    ops.append("updated")
                cursor = connection.cursor()
                cursor.execute("""
                        select IntCol
                        from TestTempTable
                        where rowid = :rid""",
                        rid=row.rowid)
                int_col, = cursor.fetchone()
                print("    Row with IntCol", int_col, "was", " and ".join(ops))
            if num_rows_deleted > 0:
                print("   ", num_rows_deleted, "rows deleted")
            print("=" * 60)

pool = oracledb.SessionPool(user=sample_env.get_main_user(),
                            password=sample_env.get_main_password(),
                            dsn=sample_env.get_connect_string(), min=2, max=5,
                            increment=1, events=True)
with pool.acquire() as connection:
    qos = oracledb.SUBSCR_QOS_QUERY | oracledb.SUBSCR_QOS_ROWIDS
    sub = connection.subscribe(callback=callback, timeout=1800, qos=qos)
    print("Subscription created with ID:", sub.id)
    query_id = sub.registerquery("select * from TestTempTable")
    print("Registered query with ID:", query_id)

while registered:
    print("Waiting for notifications....")
    time.sleep(5)
