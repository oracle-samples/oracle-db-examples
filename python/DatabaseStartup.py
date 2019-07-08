#------------------------------------------------------------------------------
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# DatabaseStartup.py
#   This script demonstrates starting up a database using Python. It is only
# possible in Oracle 10g Release 2 and higher. The connection used assumes that
# the environment variable ORACLE_SID has been set.
#
# This script requires cx_Oracle 4.3 and higher.
#------------------------------------------------------------------------------

import cx_Oracle

# the connection must be in PRELIM_AUTH mode
connection = cx_Oracle.connect("/",
        mode = cx_Oracle.SYSDBA | cx_Oracle.PRELIM_AUTH)
connection.startup()

# the following statements must be issued in normal SYSDBA mode
connection = cx_Oracle.connect("/", mode = cx_Oracle.SYSDBA)
cursor = connection.cursor()
cursor.execute("alter database mount")
cursor.execute("alter database open")

