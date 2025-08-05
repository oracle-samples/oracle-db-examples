# -----------------------------------------------------------------------------
# Copyright (c) 2025 Oracle and/or its affiliates.
#
# This software is dual-licensed to you under the Universal Permissive License
# (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
# 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
# either license.
#
# If you elect to accept the software under the Apache License, Version 2.0,
# the following applies:
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# sessionless_transactions.py
#
# Show Oracle Database 23ai Sessionless Transactions
# -----------------------------------------------------------------------------

import sys

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# this script only works with Oracle Database 23.6 or later
if sample_env.get_server_version() < (23, 6):
    sys.exit("This example requires Oracle Database 23.6 or later.")

# this script works with thin mode, or with thick mode using Oracle Client
# 23.6 or later
if not oracledb.is_thin_mode() and oracledb.clientversion()[:2] < (23, 6):
    sys.exit(
        "This example requires python-oracledb thin mode, or Oracle Client"
        " 23.6 or later"
    )

TXN_ID = b"my_transaction_id"

pool = oracledb.create_pool(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
    params=sample_env.get_pool_params(),
)

# -----------------------------------------------------------------------------
# Basic Sessionless Transaction example

print("Example 1:")

# Start and suspend a transaction
with pool.acquire() as connection1:

    # Immediately begin the transaction
    connection1.begin_sessionless_transaction(transaction_id=TXN_ID)

    with connection1.cursor() as cursor1:
        cursor1.execute(
            "insert into mytab(id, data) values (:i, :d)", [1, "Sessionless 1"]
        )
    connection1.suspend_sessionless_transaction()

    # Since the transaction is suspended, there will be no rows
    print("1st query")
    with connection1.cursor() as cursor1b:
        for r in cursor1b.execute("select * from mytab"):
            print(r)

# Resume and complete the transaction in a different connection
with pool.acquire() as connection2:

    # Immediately resume the transaction
    connection2.resume_sessionless_transaction(transaction_id=TXN_ID)

    with connection2.cursor() as cursor2:
        cursor2.execute(
            "insert into mytab(id, data) values (:i, :d)", [2, "Sessionless 2"]
        )

        # The query will show both rows inserted
        print("2nd query")
        for r in cursor2.execute("select * from mytab order by id"):
            print(r)

    # Rollback so the example can be run multiple times.
    # This concludes the Sessionless Transaction
    connection2.rollback()

# -----------------------------------------------------------------------------
# Sessionless Transaction example with custom timeouts and round-trip
# optimizations

print("Example 2:")

# Start and suspend a transaction
with pool.acquire() as connection3:

    connection3.begin_sessionless_transaction(
        transaction_id=TXN_ID,
        # The transaction can only ever be suspended for 15 seconds before it
        # is automatically rolled back
        timeout=15,
        # Only start the transaction when the next DB operation is performed
        defer_round_trip=True,
    )
    with connection3.cursor() as cursor3:
        cursor3.execute(
            "insert into mytab(id, data) values (:i, :d)",
            [3, "Sessionless 3"],
            suspend_on_success=True,  # automatically suspend on success
        )

    # Since the transaction is suspended, there will be no rows
    print("1st query")
    with connection3.cursor() as cursor3b:
        for r in cursor3b.execute("select * from mytab"):
            print(r)

# Resume and complete the transaction in a different connection
with pool.acquire() as connection4:
    connection4.resume_sessionless_transaction(
        transaction_id=TXN_ID,
        # Only wait 20 seconds if someone else is using the transaction
        timeout=20,
        # Only initiate resuming the transaction when the next DB operation is
        # performed
        defer_round_trip=True,
    )

    with connection4.cursor() as cursor4:
        cursor4.execute(
            "insert into mytab(id, data) values (:i, :d)", [4, "Sessionless 4"]
        )

        # The query will show both rows inserted
        print("2nd query")
        for r in cursor4.execute("select * from mytab order by id"):
            print(r)

    # Rollback so the example can be run multiple times.
    # This concludes the Sessionless Transaction
    connection4.rollback()
