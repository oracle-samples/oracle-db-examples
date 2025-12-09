# -----------------------------------------------------------------------------
# Copyright (c) 2025, Oracle and/or its affiliates.
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
# dataframe_numpy.py
#
# Shows how to use connection.fetch_df_all() to put data into a NumPy ndarray
# -----------------------------------------------------------------------------

import array
import sys

import numpy
import pyarrow

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
    params=sample_env.get_connect_params(),
)

# -----------------------------------------------------------------------------
#
# Fetching all records

# Get a python-oracledb DataFrame
# Adjust arraysize to tune the query fetch performance
sql = "select id from SampleQueryTab order by id"
odf = connection.fetch_df_all(statement=sql, arraysize=100)

# Convert to an ndarray via the Python DLPack specification
pyarrow_array = pyarrow.array(odf.get_column_by_name("ID"))
np = numpy.from_dlpack(pyarrow_array)

# If the array has nulls, an alternative is:
# np = pyarrow_array.to_numpy(zero_copy_only=False)

print("Type:")
print(type(np))  # <class 'numpy.ndarray'>

print("Values:")
print(np)

# Perform various NumPy operations on the ndarray

print("\nSum:")
print(numpy.sum(np))

print("\nLog10:")
print(numpy.log10(np))

# -----------------------------------------------------------------------------
#
# Fetching VECTORs

# The VECTOR example only works with Oracle Database 23.4 or later
if sample_env.get_server_version() < (23, 4):
    sys.exit("This example requires Oracle Database 23.4 or later.")

# The VECTOR example works with thin mode, or with thick mode using Oracle
# Client 23.4 or later
if not connection.thin and oracledb.clientversion()[:2] < (23, 4):
    sys.exit(
        "This example requires python-oracledb thin mode, or Oracle Client"
        " 23.4 or later"
    )

# Insert sample data
rows = [
    (array.array("d", [11.25, 11.75, 11.5]),),
    (array.array("d", [12.25, 12.75, 12.5]),),
]

with connection.cursor() as cursor:
    cursor.executemany("insert into SampleVectorTab (v64) values (:1)", rows)

# Get a python-oracledb DataFrame
# Adjust arraysize to tune the query fetch performance
sql = "select v64 from SampleVectorTab order by id"
odf = connection.fetch_df_all(statement=sql, arraysize=100)

# Convert to a NumPy ndarray
pyarrow_array = pyarrow.array(odf.get_column_by_name("V64"))
np = pyarrow_array.to_numpy(zero_copy_only=False)

print("Type:")
print(type(np))  # <class 'numpy.ndarray'>

print("Values:")
print(np)

print("\nSum:")
print(numpy.sum(np))
