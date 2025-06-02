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
# dataframe_polars.py
#
# Shows how to use connection.fetch_df_all() to efficiently put data into
# Polars DataFrames and Series.
# -----------------------------------------------------------------------------

import pyarrow
import polars

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
# Polars DataFrame

SQL1 = "select * from SampleQueryTab order by id"

# Get an OracleDataFrame
# Adjust arraysize to tune the query fetch performance
odf = connection.fetch_df_all(statement=SQL1, arraysize=100)

# Convert to a Polars DataFrame
pyarrow_table = pyarrow.Table.from_arrays(
    odf.column_arrays(), names=odf.column_names()
)
p = polars.from_arrow(pyarrow_table)

print(type(p))  # <class 'polars.dataframe.frame.DataFrame'>

r, c = p.shape
print(f"{r} rows, {c} columns")

print("\nSum:")
print(p.sum())

# -----------------------------------------------------------------------------
#
# Polars Series

SQL2 = "select id from SampleQueryTab order by id"

# Get an OracleDataFrame
# Adjust arraysize to tune the query fetch performance
odf = connection.fetch_df_all(statement=SQL2, arraysize=100)

# Convert to a Polars Series
pyarrow_array = pyarrow.array(odf.get_column_by_name("ID"))
p = polars.from_arrow(pyarrow_array)

print(type(p))  # <class 'polars.series.series.Series'>

(r,) = p.shape
print(f"{r} rows")

print("\nSum:")
print(p.sum())

print("\nLog10:")
print(p.log10())
