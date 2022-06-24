#------------------------------------------------------------------------------
# Copyright (c) 2016, 2022, Oracle and/or its affiliates.
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
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# drcp.py
#
# Demonstrates the use of Database Resident Connection Pooling (DRCP) which
# provides a connection pool in the database server, thereby reducing the cost
# of creating and tearing down client connections. The pool can be started and
# stopped in the database by issuing the following commands in SQL*Plus:
#
#   exec dbms_connection_pool.start_pool()
#   exec dbms_connection_pool.stop_pool()
#
# Statistics regarding the pool can be acquired from the following query:
#
#   select * from v$cpool_cc_stats;
#
# There is no difference in how a connection is used once it has been
# established.
#
# DRCP has most benefit when used in conjunction with a local connection pool,
# see the python-oracledb documentation.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

conn = oracledb.connect(sample_env.get_drcp_connect_string(),
                        cclass="PYCLASS", purity=oracledb.ATTR_PURITY_SELF)
cursor = conn.cursor()
print("Performing query using DRCP...")
for row in cursor.execute("select * from TestNumbers order by IntCol"):
    print(row)
