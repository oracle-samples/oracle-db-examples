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
# Shows how to use connection.fetch_df_all() to efficiently put data into a
# NumPy ndarray via the DLPack standard memory layout.
# -----------------------------------------------------------------------------

import pyarrow
import numpy

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

SQL = "select id from SampleQueryTab order by id"

# Get an OracleDataFrame
# Adjust arraysize to tune the query fetch performance
odf = connection.fetch_df_all(statement=SQL, arraysize=100)

# Convert to an ndarray via the Python DLPack specification
pyarrow_array = pyarrow.array(odf.get_column_by_name("ID"))
np = numpy.from_dlpack(pyarrow_array)

# If the array has nulls, an alternative is:
# np = pyarrow_array.to_numpy(zero_copy_only=False)

print("Type:")
print(type(np))  # <class 'numpy.ndarray'>

# Perform various numpy operations on the ndarray

print("\nSum:")
print(numpy.sum(np))

print("\nLog10:")
print(numpy.log10(np))
