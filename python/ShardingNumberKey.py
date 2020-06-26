#------------------------------------------------------------------------------
# Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ShardingNumberKey.py
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

import cx_Oracle
import SampleEnv

pool = cx_Oracle.SessionPool(SampleEnv.GetMainUser(),
        SampleEnv.GetMainPassword(), SampleEnv.GetConnectString(), min=1,
        max=5, increment=1)

def ConnectAndDisplay(shardingKey):
    print("Connecting with sharding key:", shardingKey)
    with pool.acquire(shardingkey=[shardingKey]) as conn:
        cursor = conn.cursor()
        cursor.execute("select sys_context('userenv', 'db_name') from dual")
        name, = cursor.fetchone()
        print("--> connected to database", name)

ConnectAndDisplay(100)
ConnectAndDisplay(167)
