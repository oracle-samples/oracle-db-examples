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
# database_shutdown.py
#
# Demonstrates shutting down a database using Python. The connection used
# assumes that the environment variable ORACLE_SID has been set.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# need to connect as SYSDBA or SYSOPER
connection = oracledb.connect(mode=oracledb.SYSDBA)

# first shutdown() call must specify the mode, if DBSHUTDOWN_ABORT is used,
# there is no need for any of the other steps
connection.shutdown(mode=oracledb.DBSHUTDOWN_IMMEDIATE)

# now close and dismount the database
cursor = connection.cursor()
cursor.execute("alter database close normal")
cursor.execute("alter database dismount")

# perform the final shutdown call
connection.shutdown(mode=oracledb.DBSHUTDOWN_FINAL)
