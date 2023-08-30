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
# app_context.py
#
# Demonstrates the use of application context. Application context is available
# within logon triggers and can be retrieved by using the function
# sys_context().
#------------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# client context attributes to be set
APP_CTX_NAMESPACE = "CLIENTCONTEXT"
APP_CTX_ENTRIES = [
    ( APP_CTX_NAMESPACE, "ATTR1", "VALUE1" ),
    ( APP_CTX_NAMESPACE, "ATTR2", "VALUE2" ),
    ( APP_CTX_NAMESPACE, "ATTR3", "VALUE3" )
]

connection = oracledb.connect(user=sample_env.get_main_user(),
                              password=sample_env.get_main_password(),
                              dsn=sample_env.get_connect_string(),
                              appcontext=APP_CTX_ENTRIES)

with connection.cursor() as cursor:

    for namespace, name, value in APP_CTX_ENTRIES:
        cursor.execute("select sys_context(:1, :2) from dual",
                       (namespace, name))
        value, = cursor.fetchone()
        print("Value of context key", name, "is", value)
