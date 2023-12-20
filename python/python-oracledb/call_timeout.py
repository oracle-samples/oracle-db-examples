# -----------------------------------------------------------------------------
# Copyright (c) 2019, 2023, Oracle and/or its affiliates.
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
# call_timeout.py
#
# Demonstrates the use of the Oracle Client 18c feature that enables round
# trips to the database to time out if a specified amount of time
# (in milliseconds) has passed without a response from the database.
#
# This script requires Oracle Client 18.1 and higher when using thick mode.
# -----------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
)

connection.call_timeout = 2000
print("Call timeout set at", connection.call_timeout, "milliseconds...")

with connection.cursor() as cursor:
    cursor.execute("select sysdate from dual")
    (today,) = cursor.fetchone()
    print("Fetch of current date before timeout:", today)

    # dbms_session.sleep() replaces dbms_lock.sleep() from Oracle Database 18c
    sleep_proc_name = (
        "dbms_session.sleep"
        if int(connection.version.split(".")[0]) >= 18
        else "dbms_lock.sleep"
    )

    print("Sleeping...should time out...")
    try:
        cursor.callproc(sleep_proc_name, (3,))
    except oracledb.DatabaseError as e:
        print("ERROR:", e)

    cursor.execute("select sysdate from dual")
    (today,) = cursor.fetchone()
    print("Fetch of current date after timeout:", today)
