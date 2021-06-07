#------------------------------------------------------------------------------
# Copyright (c) 2020, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# sharding_number_key.py
#   This script demonstrates how to use sharding keys with a sharded database.
# The sample schema provided does not include support for running this demo. A
# sharded database must first be created. Information on how to create a
# sharded database can be found in the documentation:
# https://www.oracle.com/pls/topic/lookup?ctx=dblatest&id=SHARD
#
# This script requires cx_Oracle 6.1 and higher but it is recommended to use
# cx_Oracle 7.3 and higher in order to avoid a set of known issues when using
# sharding capabilities.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

pool = oracledb.SessionPool(user=sample_env.get_main_user(),
                            password=sample_env.get_main_password(),
                            dsn=sample_env.get_connect_string(), min=1, max=5,
                            increment=1)

def connect_and_display(sharding_key):
    print("Connecting with sharding key:", sharding_key)
    with pool.acquire(shardingkey=[sharding_key]) as conn:
        cursor = conn.cursor()
        cursor.execute("select sys_context('userenv', 'db_name') from dual")
        name, = cursor.fetchone()
        print("--> connected to database", name)

connect_and_display(100)
connect_and_display(167)
