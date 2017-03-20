#------------------------------------------------------------------------------
# Copyright 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# DatabaseShutdown.py
#   This script demonstrates shutting down a database using Python. It is only
# possible in Oracle 10g Release 2 and higher. The connection used assumes that
# the environment variable ORACLE_SID has been set.
#
# This script requires cx_Oracle 4.3 and higher.
#------------------------------------------------------------------------------

import cx_Oracle

# need to connect as SYSDBA or SYSOPER
connection = cx_Oracle.connect("/", mode = cx_Oracle.SYSDBA)

# first shutdown() call must specify the mode, if DBSHUTDOWN_ABORT is used,
# there is no need for any of the other steps
connection.shutdown(mode = cx_Oracle.DBSHUTDOWN_IMMEDIATE)

# now close and dismount the database
cursor = connection.cursor()
cursor.execute("alter database close normal")
cursor.execute("alter database dismount")

# perform the final shutdown call
connection.shutdown(mode = cx_Oracle.DBSHUTDOWN_FINAL)

