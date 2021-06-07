#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# app_context.py
#   This script demonstrates the use of application context. Application
# context is available within logon triggers and can be retrieved by using the
# function sys_context().
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

# define constants used throughout the script; adjust as desired
APP_CTX_NAMESPACE = "CLIENTCONTEXT"
APP_CTX_ENTRIES = [
    ( APP_CTX_NAMESPACE, "ATTR1", "VALUE1" ),
    ( APP_CTX_NAMESPACE, "ATTR2", "VALUE2" ),
    ( APP_CTX_NAMESPACE, "ATTR3", "VALUE3" )
]

connection = oracledb.connect(sample_env.get_main_connect_string(),
                              appcontext=APP_CTX_ENTRIES)
cursor = connection.cursor()
for namespace, name, value in APP_CTX_ENTRIES:
    cursor.execute("select sys_context(:1, :2) from dual", (namespace, name))
    value, = cursor.fetchone()
    print("Value of context key", name, "is", value)
