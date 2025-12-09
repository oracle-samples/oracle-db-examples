# -----------------------------------------------------------------------------
# Copyright (c) 2016, 2025, Oracle and/or its affiliates.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
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
# transaction_guard.py
#
# Demonstrates the use of Transaction Guard to verify if a transaction has
# completed, ensuring that a duplicate transaction is not created or attempted
# if the application chooses to handle the error. This
# feature is only available in Oracle Database 12.1. It follows loosely the
# OCI sample provided by Oracle in its documentation about OCI and Transaction
# Guard.
#
# Run the following as SYSDBA to set up Transaction Guard
#
#     grant execute on dbms_app_cont to pythondemo;
#
#     declare
#         t_Params dbms_service.svc_parameter_array;
#     begin
#         t_Params('COMMIT_OUTCOME') := 'true';
#         t_Params('RETENTION_TIMEOUT') := 604800;
#         dbms_service.create_service('orcl-tg', 'orcl-tg', t_Params);
#         dbms_service.start_service('orcl-tg');
#     end;
#     /
# -----------------------------------------------------------------------------

import sys

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# constants
CONNECT_STRING = "localhost/orcl-tg"

# create transaction and generate a recoverable error
pool = oracledb.create_pool(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=CONNECT_STRING,
    min=1,
    max=9,
    increment=2,
)
connection = pool.acquire()
cursor = connection.cursor()
cursor.execute("delete from TestTempTable where IntCol = 1")
cursor.execute("insert into TestTempTable values (1, null)")

try:
    sql = """select unique
             'alter system kill session '''||sid||','||serial#||''';'
             from v$session_connect_info
             where sid = sys_context('USERENV', 'SID')"""
    (killsql,) = connection.cursor().execute(sql).fetchone()
    print(f"Execute this SQL statement as a DBA user in SQL*Plus:\n {killsql}")
except Exception:
    print(
        "As a DBA user in SQL*Plus, use ALTER SYSTEM KILL SESSION "
        f"to terminate the {sample_env.get_main_user()} session now."
    )

input("Press ENTER when complete.")

ltxid = connection.ltxid
if not ltxid:
    sys.exit("Logical transaction not available. Terminating.")
try:
    connection.commit()  # this should fail
    sys.exit("Session was not killed. Sample cannot continue.")
except oracledb.DatabaseError as e:
    (error_obj,) = e.args
    print("Session is recoverable:", error_obj.isrecoverable)
    if not error_obj.isrecoverable:
        sys.exit("Session is not recoverable. Terminating.")
pool.drop(connection)

# check if previous transaction completed
connection = pool.acquire()
cursor = connection.cursor()
args = (oracledb.Binary(ltxid), cursor.var(bool), cursor.var(bool))
_, committed, completed = cursor.callproc(
    "dbms_app_cont.get_ltxid_outcome", args
)
print("Failed transaction was committed:", committed)
print("Failed call was completed:", completed)
