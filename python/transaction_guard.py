#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# transaction_guard.py
#   This script demonstrates the use of Transaction Guard to verify if a
# transaction has completed, ensuring that a duplicate transaction is not
# created or attempted if the application chooses to handle the error. This
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
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

import sys

import cx_Oracle as oracledb
import sample_env

# constants
CONNECT_STRING = "localhost/orcl-tg"

# create transaction and generate a recoverable error
pool = oracledb.SessionPool(user=sample_env.get_main_user(),
                            password=sample_env.get_main_password(),
                            dsn=CONNECT_STRING, min=1, max=9, increment=2)
connection = pool.acquire()
cursor = connection.cursor()
cursor.execute("""
        delete from TestTempTable
        where IntCol = 1""")
cursor.execute("""
        insert into TestTempTable
        values (1, null)""")
input("Please kill %s session now. Press ENTER when complete." % \
        sample_env.get_main_user())
try:
    connection.commit() # this should fail
    sys.exit("Session was not killed. Terminating.")
except oracledb.DatabaseError as e:
    error_obj, = e.args
    if not error_obj.isrecoverable:
        sys.exit("Session is not recoverable. Terminating.")
ltxid = connection.ltxid
if not ltxid:
    sys.exit("Logical transaction not available. Terminating.")
pool.drop(connection)

# check if previous transaction completed
connection = pool.acquire()
cursor = connection.cursor()
args = (oracledb.Binary(ltxid), cursor.var(bool), cursor.var(bool))
_, committed, completed = cursor.callproc("dbms_app_cont.get_ltxid_outcome",
                                          args)
print("Failed transaction was committed:", committed)
print("Failed call was completed:", completed)
