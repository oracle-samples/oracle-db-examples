#! /usr/bin/env python3.9

# -----------------------------------------------------------------------------
# Copyright (c) 2022, 2024, Oracle and/or its affiliates.
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

# NAME
#
#   setup.py
#
# PURPOSE
#
#   Creates the python-oracledb sample schema after waiting for the database to
#   open.
#
#   If this times out, wait a few minutes for the database to finish
#   initializing and then rerun it.
#
# USAGE
#
#   python setup.py

import oracledb
import os
import time

oracledb.init_oracle_client()

pw = os.environ.get("ORACLE_PASSWORD")
os.environ["PYO_SAMPLES_ADMIN_PASSWORD"] = pw

c = None

for i in range(30):
    try:
        c = oracledb.connect(
            user="system",
            password=pw,
            dsn="localhost/freepdb1",
            tcp_connect_timeout=5,
        )
        break
    except (OSError, oracledb.Error):
        print("Waiting for database to open")
        time.sleep(5)

if c:
    print("PDB is open")
else:
    print("PDB did not open in allocated time")
    print("Try again in a few minutes")
    exit()


print("Enabling per-PDB DRCP")

c = oracledb.connect(mode=oracledb.SYSDBA)
cursor = c.cursor()
cursor.execute("alter pluggable database all close")
cursor.execute(
    "alter system set enable_per_pdb_drcp=true scope=spfile sid='*'"
)

c = oracledb.connect(mode=oracledb.SYSDBA | oracledb.PRELIM_AUTH)
c.startup(force=True)

c = oracledb.connect(mode=oracledb.SYSDBA)
cursor = c.cursor()
cursor.execute("alter database mount")
cursor.execute("alter database open")

c = oracledb.connect(
    user="sys", password=pw, dsn="localhost/freepdb1", mode=oracledb.SYSDBA
)
cursor = c.cursor()
cursor.callproc("dbms_connection_pool.start_pool")

# create_schema.py will be appended here by the Dockerfile
