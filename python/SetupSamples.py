#------------------------------------------------------------------------------
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# SetupSamples.py
#
# Creates users and populates their schemas with the tables and packages
# necessary for the cx_Oracle samples. An edition is also created for the
# demonstration of PL/SQL editioning.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

import SampleEnv
import DropSamples

# connect as SYSDBA
conn = cx_Oracle.connect(SampleEnv.GetSysdbaConnectString(),
        mode = cx_Oracle.SYSDBA)

# drop existing users and editions, if applicable
DropSamples.DropSamples(conn)

# create sample schema and edition
print("Creating sample schemas and edition...")
SampleEnv.RunSqlScript(conn, "SetupSamples",
        main_user = SampleEnv.GetMainUser(),
        main_password = SampleEnv.GetMainPassword(),
        edition_user = SampleEnv.GetEditionUser(),
        edition_password = SampleEnv.GetEditionPassword(),
        edition_name = SampleEnv.GetEditionName())
print("Done.")

