#------------------------------------------------------------------------------
# Copyright 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# AppContext.py
#   This script demonstrates the use of application context. Application
# context is available within logon triggers and can be retrieved by using the
# function sys_context().
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

# define constants used throughout the script; adjust as desired
CONNECT_STRING = "cx_Oracle/dev@localhost/orcl"
APP_CTX_NAMESPACE = "CLIENTCONTEXT"
APP_CTX_ENTRIES = [
    ( APP_CTX_NAMESPACE, "ATTR1", "VALUE1" ),
    ( APP_CTX_NAMESPACE, "ATTR2", "VALUE2" ),
    ( APP_CTX_NAMESPACE, "ATTR3", "VALUE3" )
]

connection = cx_Oracle.Connection(CONNECT_STRING, appcontext = APP_CTX_ENTRIES)
cursor = connection.cursor()
for namespace, name, value in APP_CTX_ENTRIES:
    cursor.execute("select sys_context(:1, :2) from dual", (namespace, name))
    value, = cursor.fetchone()
    print("Value of context key", name, "is", value)

