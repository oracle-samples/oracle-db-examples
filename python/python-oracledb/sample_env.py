#------------------------------------------------------------------------------
# Copyright (c) 2017, 2023, Oracle and/or its affiliates.
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
# Sets the environment used by the python-oracledb sample scripts. Production
# applications should consider using External Authentication to avoid hard
# coded credentials.
#
# The samples will prompt for credentials and schema information unless the
# following environment variables are set:
#
#   PYO_SAMPLES_ORACLE_CLIENT_PATH: Oracle Client or Instant Client library dir
#   PYO_SAMPLES_ADMIN_USER: privileged administrative user for setting up samples
#   PYO_SAMPLES_ADMIN_PASSWORD: password of PYO_SAMPLES_ADMIN_USER
#   PYO_SAMPLES_CONNECT_STRING: database connection string
#   PYO_SAMPLES_DRCP_CONNECT_STRING: database connection string for DRCP
#   PYO_SAMPLES_MAIN_USER: user to be created. Used for most samples
#   PYO_SAMPLES_MAIN_PASSWORD: password for PYO_SAMPLES_MAIN_USER
#   PYO_SAMPLES_EDITION_USER: user to be created for editiong samples
#   PYO_SAMPLES_EDITION_PASSWORD: password of PYO_SAMPLES_EDITION_USER
#   PYO_SAMPLES_EDITION_NAME: name of edition for editioning samples
#   PYO_SAMPLES_DRIVER_MODE: python-oracledb mode (Thick or thin) to use
#
# - On Windows set PYO_SAMPLES_ORACLE_CLIENT_PATH if Oracle libraries are not
#   in PATH.  On macOS set the variable to the Instant Client directory.  On
#   Linux do not set the variable; instead set LD_LIBRARY_PATH or configure
#   ldconfig before running Python.
#
# - PYO_SAMPLES_ADMIN_USER should be the administrative user ADMIN for cloud
#   databases and SYSTEM for on premises databases.
#
# - PYO_SAMPLES_CONNECT_STRING is the connection string for your database. It
#   can be set to an Easy Connect string or to a Net Service Name from a
#   tnsnames.ora file or external naming service.
#
#   The Easy Connect string is generally easiest. The basic syntax is:
#
#     host_name[:port][/service_name][:server_type]
#
#   Commonly just the host_name and service_name are needed
#   e.g. "localhost/orclpdb" or "localhost/XEPDB1".
#
#   If PYO_SAMPLES_CONNECT_STRING is an aliases from tnsnames.ora file, then
#   set the TNS_ADMIN environment variable and put the file in
#   $TNS_ADMIN/tnsnames.ora.  Alternatively for python-oracledb Thick mode, the
#   file will be automatically used if it is in a location such as
#   instantclient_XX_Y/network/admin/tnsnames.ora,
#   $ORACLE_HOME/network/admin/tnsnames.ora or /etc/tnsnames.ora.
#
# - PYO_SAMPLES_DRCP_CONNECT_STRING should be a connect string requesting a
#   pooled server, for example "localhost/orclpdb:pooled".
#
# - PYO_SAMPLES_MAIN_USER and PYO_SAMPLES_EDITION_USER are names of users that
#   will be created and used for running samples.  Choose names that do not
#   exist because the schemas will be dropped and then recreated.
#
# - PYO_SAMPLES_EDITION_NAME can be set to a new name to be used for Edition
#   Based Redefinition examples.
#
# - PYO_SAMPLES_DRIVER_MODE should be "thin" or "thick".  It is used by samples
#   that can run in both python-oracledb modes.
#
#------------------------------------------------------------------------------

import getpass
import os
import platform
import sys

import oracledb

# default values
DEFAULT_MAIN_USER = "pythondemo"
DEFAULT_EDITION_USER = "pythoneditions"
DEFAULT_EDITION_NAME = "python_e1"
DEFAULT_CONNECT_STRING = "localhost/orclpdb1"
DEFAULT_DRCP_CONNECT_STRING = "localhost/orclpdb1:pooled"

# dictionary containing all parameters; these are acquired as needed by the
# methods below (which should be used instead of consulting this dictionary
# directly) and then stored so that a value is not requested more than once
PARAMETERS = {}

def get_value(name, label, default_value=None, password=False):
    value = PARAMETERS.get(name)
    if value is not None:
        return value
    value = os.environ.get(name)
    if value is None:
        if default_value is not None:
            label += " [%s]" % default_value
        label += ": "
        if not password:
            value = input(label).strip()
        else:
            value = getpass.getpass(label)
        if not value:
            value = default_value
    PARAMETERS[name] = value
    return value

def get_main_user():
    return get_value("PYO_SAMPLES_MAIN_USER", "Main User Name",
                     DEFAULT_MAIN_USER)

def get_main_password():
    return get_value("PYO_SAMPLES_MAIN_PASSWORD",
                     f"Password for {get_main_user()}", password=True)

def get_edition_user():
    return get_value("PYO_SAMPLES_EDITION_USER", "Edition User Name",
                     DEFAULT_EDITION_USER)

def get_edition_password():
    return get_value("PYO_SAMPLES_EDITION_PASSWORD",
                     f"Password for {get_edition_user()}", password=True)

def get_edition_name():
    return get_value("PYO_SAMPLES_EDITION_NAME", "Edition Name",
                     DEFAULT_EDITION_NAME)

def get_connect_string():
    return get_value("PYO_SAMPLES_CONNECT_STRING", "Connect String",
                     DEFAULT_CONNECT_STRING)

def get_drcp_connect_string():
    return get_value("PYO_SAMPLES_DRCP_CONNECT_STRING", "DRCP Connect String",
                     DEFAULT_DRCP_CONNECT_STRING)

def get_driver_mode():
    return get_value("PYO_SAMPLES_DRIVER_MODE", "Driver mode (thin|thick)",
                     "thin")

def get_is_thin():
    return get_driver_mode() == "thin"

def get_edition_connect_string():
    return "%s/%s@%s" % \
            (get_edition_user(), get_edition_password(), get_connect_string())

def get_admin_connect_string():
    admin_user = get_value("PYO_SAMPLES_ADMIN_USER", "Administrative user",
                           "admin")
    admin_password = get_value("PYO_SAMPLES_ADMIN_PASSWORD",
                               f"Password for {admin_user}", password=True)
    return "%s/%s@%s" % (admin_user, admin_password, get_connect_string())

def get_oracle_client():
    if ((platform.system() == "Darwin" and platform.machine() == "x86_64") or
        platform.system() == "Windows"):
        return get_value("PYO_SAMPLES_ORACLE_CLIENT_PATH",
                         "Oracle Instant Client Path")

def get_server_version():
    name = "SERVER_VERSION"
    value = PARAMETERS.get(name)
    if value is None:
        conn = oracledb.connect(user=get_main_user(),
                                password=get_main_password(),
                                dsn=get_connect_string())
        value = tuple(int(s) for s in conn.version.split("."))[:2]
        PARAMETERS[name] = value
    return value

def run_sql_script(conn, script_name, **kwargs):
    statement_parts = []
    cursor = conn.cursor()
    replace_values = [("&" + k + ".", v) for k, v in kwargs.items()] + \
                     [("&" + k, v) for k, v in kwargs.items()]
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    file_name = os.path.join(script_dir, "sql", script_name + ".sql")
    for line in open(file_name):
        if line.strip() == "/":
            statement = "".join(statement_parts).strip()
            if statement:
                for search_value, replace_value in replace_values:
                    statement = statement.replace(search_value, replace_value)
                try:
                    cursor.execute(statement)
                except:
                    print("Failed to execute SQL:", statement)
                    raise
            statement_parts = []
        else:
            statement_parts.append(line)
    cursor.execute("""
            select name, type, line, position, text
            from dba_errors
            where owner = upper(:owner)
            order by name, type, line, position""",
            owner = get_main_user())
    prev_name = prev_obj_type = None
    for name, obj_type, line_num, position, text in cursor:
        if name != prev_name or obj_type != prev_obj_type:
            print("%s (%s)" % (name, obj_type))
            prev_name = name
            prev_obj_type = obj_type
        print("    %s/%s %s" % (line_num, position, text))
