#------------------------------------------------------------------------------
# Copyright (c) 2022, 2023, Oracle and/or its affiliates.
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
# oracledb_upgrade.py
#
# Example module to assist upgrading large applications from cx_Oracle 8 to
# python-oracledb (the renamed major new release of cx_Oracle).
#
# An environment variable ORA_PYTHON_DRIVER_TYPE can be set to determine
# whether to use cx_Oracle, python-oracledb Thin mode, or python-oracledb Thick
# mode.
#
# NOTE
#
#   Most users DO NOT need this file. Instead you can do:
#
#   - Install python-oracledb:
#
#       python -m pip install oracledb
#
#   - Change "import cx_Oracle" to:
#
#       import oracledb as cx_Oracle
#
#   - Remove any call to init_oracle_client() if you want to use
#     python-oracledb Thin mode.  Conversely add a call if you want to use
#     Thick mode.
#
#   - Use named parameters in calls to connect(), Connection() and
#     SessionPool():
#
#       c = oracledb.connect(user="un", password="pw", dsn="cs")
#
#   Other updates noted in the upgrade documentation may also need to be
#   made.
#
#   However, if you want to toggle which driver to use or have code where
#   changes are not easy, then this file may help.
#
# USAGE
#
#   - Install python-oracledb:
#
#       python -m pip install oracledb
#
#   - Change your code's first "import cx_Oracle" to:
#
#       import oracledb_upgrade as cx_Oracle
#
#     This needs to be imported before cx_Oracle is ever imported for it to
#     take effect. Subsequent imports do not need to be changed but may be,
#     if desired.
#
#   - Remove any call to init_oracle_client() from your existing code base.
#
#   - Set lib_dir (in the module code below) to your Oracle Client library
#     directory if you are calling init_oracle_client() with that parameter in
#     your existing cx_Oracle code on Windows or macOS, and you intend to use
#     python-oracledb Thick mode or cx_Oracle.
#
#   - Review python-oracledb documentation for additional changes that may be
#     needed in your code.
#
#   - Set the environment variable ORA_PYTHON_DRIVER_TYPE to "cx", "thin", or
#     "thick" to choose which module to use:
#
#       thin -> python-oracledb Thin mode (the default)
#
#       thick -> python-oracledb Thick mode
#
#       cx -> cx_Oracle
#
#   - Run your application
#
#     An example application showing this module in use is:
#
#       import oracledb_upgrade as cx_Oracle
#       import os
#
#       un = os.environ.get("PYTHON_USERNAME")
#       pw = os.environ.get("PYTHON_PASSWORD")
#       cs = os.environ.get("PYTHON_CONNECTSTRING")
#
#       connection = cx_Oracle.connect(user=un, password=pw, dsn=cs)
#       with connection.cursor() as cursor:
#           sql = """SELECT UNIQUE CLIENT_DRIVER
#                    FROM V$SESSION_CONNECT_INFO
#                    WHERE SID = SYS_CONTEXT('USERENV', 'SID')"""
#           for r, in cursor.execute(sql):
#               print(r)
#
#------------------------------------------------------------------------------

import os
import sys
import platform

import cx_Oracle
import oracledb

# Set True to print which driver and mode is being used
MODE_TRACE = False

# Enable a 'shim' if your cx_Oracle code makes connect(), Connection() or
# SessionPool() calls that use positional parameters e.g. like:
#   cx_Oracle.connect(username, password, connect_string)
ALLOW_POSITIONAL_CONNECT_ARGS = True

# On macOS and Windows set lib_dir to your Instant Client path if you are
# currently calling init_oracle_client() in your application. On Linux do not
# set lib_dir; instead set LD_LIBRARY_PATH or configure ldconfig before running
# Python.
lib_dir = None
if platform.system() == "Darwin" and platform.machine() == "x86_64":
    lib_dir = os.environ.get("HOME")+"/Downloads/instantclient_19_8"
elif platform.system() == "Windows":
    lib_dir = r"C:\oracle\instantclient_19_14"

# Determine which module and mode to use.
# The default is python-oracledb Thin mode.
driver_type = os.environ.get("ORA_PYTHON_DRIVER_TYPE", "thin")

if driver_type.lower() == "cx":
    if MODE_TRACE: print("Using cx_Oracle")
    from cx_Oracle import *
    sys.modules["oracledb"] = cx_Oracle
    sys.modules["cx_Oracle"] = cx_Oracle
    oracledb.init_oracle_client(lib_dir=lib_dir)
else:
    from oracledb import *
    sys.modules["oracledb"] = oracledb
    sys.modules["cx_Oracle"] = oracledb
    if driver_type.lower() == "thick":
        if MODE_TRACE: print("Using python-oracledb thick")
        # For python-oracledb Thick mode, init_oracle_client() MUST be called
        # on all operating systems. Whether to use a lib_dir value depends on
        # how your system library search path is configured.
        oracledb.init_oracle_client(lib_dir=lib_dir)
    else:
        if MODE_TRACE: print("Using python-oracledb thin")

# If your existing cx_Oracle code never used positional arguments for
# connection and pool creation calls then inject_connect_shim() is not
# necessary and you can set ALLOW_POSITIONAL_CONNECT_ARGS to False
def inject_connect_shim():
    """
    Allow python-oracledb to use positional arguments in connect(),
    Connection() and SessionPool() signatures as allowed by cx_Oracle.
    """

    class ShimConnection(oracledb.Connection):

        def __init__(self, user=None, password=None, dsn=None,
                     mode=oracledb.DEFAULT_AUTH, handle=0, pool=None,
                     threaded=False, events=False, cclass=None,
                     purity=oracledb.ATTR_PURITY_DEFAULT,
                     newpassword=None, encoding=None, nencoding=None,
                     edition=None, appcontext=[], tag=None,
                     matchanytag=False, shardingkey=[],
                     supershardingkey=[], stmtcachesize=20):
            if dsn is None and password is None:
                dsn = user
                user = None
            super().__init__(dsn=dsn, user=user, password=password,
                             mode=mode, handle=handle, pool=pool,
                             threaded=threaded, events=events, cclass=cclass,
                             purity=purity, newpassword=newpassword,
                             edition=edition, appcontext=appcontext, tag=tag,
                             matchanytag=matchanytag, shardingkey=shardingkey,
                             supershardingkey=supershardingkey,
                             stmtcachesize=stmtcachesize)

    class ShimPool(oracledb.SessionPool):

        def __init__(self, user=None, password=None, dsn=None, min=1, max=2,
                     increment=1, connectiontype=oracledb.Connection,
                     threaded=True, getmode=oracledb.SPOOL_ATTRVAL_NOWAIT,
                     events=False, homogeneous=True, externalauth=False,
                     encoding=None, nencoding=None, edition=None, timeout=0,
                     wait_timeout=0, max_lifetime_session=0, session_callback=None,
                     max_sessions_per_shard=0, soda_metadata_cache=False,
                     stmtcachesize=20, ping_interval=60):

            super().__init__(dsn=dsn, user=user, password=password,
                             min=min, max=max, increment=increment,
                             connectiontype=connectiontype, threaded=threaded,
                             getmode=getmode, events=events, homogeneous=homogeneous,
                             externalauth=externalauth, encoding=encoding,
                             nencoding=nencoding, edition=edition, timeout=timeout,
                             wait_timeout=wait_timeout,
                             max_lifetime_session=max_lifetime_session,
                             session_callback=session_callback,
                             max_sessions_per_shard=max_sessions_per_shard,
                             soda_metadata_cache=soda_metadata_cache,
                             stmtcachesize=stmtcachesize, ping_interval=ping_interval)

    global connect
    connect = ShimConnection
    global Connection
    Connection = ShimConnection
    global SessionPool
    SessionPool = ShimPool

if ALLOW_POSITIONAL_CONNECT_ARGS and driver_type.lower() != "cx":
    inject_connect_shim()
