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
# dataframe_pandas_async.py
#
# An asynchronous version of dataframe_pandas.py
#
# Shows how to use AsyncConnection.fetch_df_all() and
# AsyncConnection.fetch_df_batches(). This example then creates Pandas
# dataframes. Alternative dataframe libraries could be used similar to the
# other, synchronous, data frame samples.
# -----------------------------------------------------------------------------

import array
import asyncio
import sys

import numpy
import pandas
import pyarrow

import oracledb
import sample_env


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_connect_params(),
    )

    SQL = "select id, name from SampleQueryTab order by id"

    # -------------------------------------------------------------------------
    #
    # Fetching all records

    # Get a python-oracledb DataFrame.
    # Adjust arraysize to tune the query fetch performance
    odf = await connection.fetch_df_all(statement=SQL, arraysize=100)

    # Get a Pandas DataFrame from the data
    df = pyarrow.table(odf).to_pandas()

    # Perform various Pandas operations on the DataFrame

    print("Columns:")
    print(df.columns)

    print("\nDataframe description:")
    print(df.describe())

    print("\nLast three rows:")
    print(df.tail(3))

    print("\nTransform:")
    print(df.T)

    # -------------------------------------------------------------------------
    #
    # Batch record fetching
    #
    # Note that since this particular example ends up with all query rows being
    # held in memory, it would be more efficient to use fetch_df_all() as shown
    # above.

    print("\nFetching in batches:")
    df = pandas.DataFrame()

    # Tune 'size' for your data set. Here it is small to show the batch fetch
    # behavior on the sample table.
    async for odf in connection.fetch_df_batches(statement=SQL, size=10):
        df_b = pyarrow.table(odf).to_pandas()
        print(f"Appending {df_b.shape[0]} rows")
        df = pandas.concat([df, df_b], ignore_index=True)

    r, c = df.shape
    print(f"{r} rows, {c} columns")

    print("\nLast three rows:")
    print(df.tail(3))

    # -------------------------------------------------------------------------
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
        await cursor.executemany(
            "insert into SampleVectorTab (v64) values (:1)", rows
        )

    # Get a python-oracledb DataFrame.
    # Adjust arraysize to tune the query fetch performance
    sql = "select id, v64 from SampleVectorTab order by id"
    odf = await connection.fetch_df_all(statement=sql, arraysize=100)

    # Get a Pandas DataFrame from the data
    df = pyarrow.table(odf).to_pandas()

    # Perform various Pandas operations on the DataFrame

    print("\nDataFrame:")
    print(df)

    print("\nMean:")
    print(pandas.DataFrame(df["V64"].tolist()).mean())

    print("\nList:")
    df2 = pandas.DataFrame(df["V64"].tolist()).T
    print(df2)
    print(df2.sum())

    # You can manipulate vectors using Pandas's apply or list comprehension
    # with NumPy for efficient array operations.

    # Scaling all vectors by a factor of two
    print("\nScaled:")
    df["SCALED_V64_COL"] = df["V64"].apply(lambda x: numpy.array(x) * 2)
    print(df)

    # Calculating vector norms
    #
    # L2_NORM = Straight line distance from the origin to vector's endpoint
    # L1_NORM = Sum of absolute values of the vector's components
    # Linf_NORM = Largest absolute component of the vector; useful in scenarios
    # where maximum deviation matters
    print("\nNorms:")
    df["L2_NORM"] = df["V64"].apply(lambda x: numpy.linalg.norm(x, ord=2))
    df["L1_NORM"] = df["V64"].apply(lambda x: numpy.linalg.norm(x, ord=1))
    df["Linf_NORM"] = df["V64"].apply(
        lambda x: numpy.linalg.norm(x, ord=numpy.inf)
    )
    print(df)

    # Calculating the vector dot product with a reference vector
    print("\nDot product:")
    ref_vector = numpy.array([1, 10, 10])
    df["DOT_PRODUCT"] = df["V64"].apply(lambda x: numpy.dot(x, ref_vector))
    print(df)


asyncio.run(main())
