#------------------------------------------------------------------------------
# Copyright 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# DRCP.py
#   This script demonstrates the use of Database Resident Connection Pooling
# (DRCP) which provides a connection pool in the database server, thereby
# reducing the cost of creating and tearing down client connections. The pool
# can be started and stopped in the database by issuing the following commands
# in SQL*Plus:
#
#   exec dbms_connection_pool.start_pool()
#   exec dbms_connection_pool.stop_pool()
#
# Statistics regarding the pool can be acquired from the following query:
#
#   select * from v$pool_cc_stats;
#
# There is no difference in how a connection is used once it has been
# established.
#
# This script requires cx_Oracle 5.0 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

conn = cx_Oracle.Connection("cx_Oracle/dev@localhost/orcl:pooled",
        cclass = "PYCLASS", purity = cx_Oracle.ATTR_PURITY_SELF)
cursor = conn.cursor()
print("Performing query using DRCP...")
for row in cursor.execute("select * from TestNumbers order by IntCol"):
    print(row)

