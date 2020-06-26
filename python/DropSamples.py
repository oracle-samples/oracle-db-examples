#------------------------------------------------------------------------------
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# DropSamples.py
#
# Drops the database objects used for the cx_Oracle samples.
#------------------------------------------------------------------------------

import cx_Oracle
import SampleEnv

def DropSamples(conn):
    print("Dropping sample schemas and edition...")
    SampleEnv.RunSqlScript(conn, "DropSamples",
            main_user = SampleEnv.GetMainUser(),
            edition_user = SampleEnv.GetEditionUser(),
            edition_name = SampleEnv.GetEditionName())

if __name__ == "__main__":
    conn = cx_Oracle.connect(SampleEnv.GetAdminConnectString())
    DropSamples(conn)
    print("Done.")
