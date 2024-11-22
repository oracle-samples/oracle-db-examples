# -----------------------------------------------------------------------------
# Copyright (c) 2020, 2023, Oracle and/or its affiliates.
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

# -----------------------------------------------------------------------------
# sharding_number_key.py
#
# Demonstrates how to use sharding keys with a sharded database.
# The sample schema provided does not include support for running this demo. A
# sharded database must first be created. Information on how to create a
# sharded database can be found in the documentation:
# https://www.oracle.com/pls/topic/lookup?ctx=dblatest&id=SHARD
# -----------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

pool = oracledb.create_pool(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
    min=1,
    max=5,
    increment=1,
)


def connect_and_display(sharding_key):
    print("Connecting with sharding key:", sharding_key)
    with pool.acquire(shardingkey=[sharding_key]) as conn:
        cursor = conn.cursor()
        cursor.execute("select sys_context('userenv', 'db_name') from dual")
        (name,) = cursor.fetchone()
        print("--> connected to database", name)


connect_and_display(100)
connect_and_display(167)
