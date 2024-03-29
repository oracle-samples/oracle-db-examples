#! /usr/bin/env python3.9
#
# NAME
#
#   setup.py
#
# PURPOSE
#
#   Creates the python-oracledb sample schema after waiting for the database to
#   open.
#
# USAGE
#
#   ./setup.py

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
