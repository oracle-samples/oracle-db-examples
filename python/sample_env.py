#------------------------------------------------------------------------------
# Copyright (c) 2017, 2022, Oracle and/or its affiliates.
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
# You can set values in environment variables to bypass the sample requesting
# the information it requires.
#
#   PYO_SAMPLES_MAIN_USER: user used for most samples
#   PYO_SAMPLES_MAIN_PASSWORD: password of user used for most samples
#   PYO_SAMPLES_EDITION_USER: user for editioning
#   PYO_SAMPLES_EDITION_PASSWORD: password of user for editioning
#   PYO_SAMPLES_EDITION_NAME: name of edition for editioning
#   PYO_SAMPLES_CONNECT_STRING: connect string
#   PYO_SAMPLES_DRCP_CONNECT_STRING: DRCP connect string
#   PYO_SAMPLES_ADMIN_USER: admin user for setting up samples
#   PYO_SAMPLES_ADMIN_PASSWORD: admin password for setting up samples
#   PYO_SAMPLES_DRIVER_MODE: python-oracledb mode (thick or thin) to use
#   PYO_SAMPLES_ORACLE_CLIENT_PATH: Oracle Client or Instant Client library dir
#
# On Windows set PYO_SAMPLES_ORACLE_CLIENT_PATH if Oracle libraries are not in
# PATH.  On macOS set the variable to the Instant Client directory.  On Linux
# do not set the variable; instead set LD_LIBRARY_PATH or configure ldconfig
# before running Python.
#
# PYO_SAMPLES_CONNECT_STRING can be set to an Easy Connect string, or a
# Net Service Name from a tnsnames.ora file or external naming service,
# or it can be the name of a local Oracle database instance.
#
# If using Instant Client, then an Easy Connect string is generally
# appropriate. The syntax is:
#
#   [//]host_name[:port][/service_name][:server_type][/instance_name]
#
# Commonly just the host_name and service_name are needed
# e.g. "localhost/orclpdb1" or "localhost/XEPDB1"
#
# If using a tnsnames.ora file, the file can be in a default
# location such as $ORACLE_HOME/network/admin/tnsnames.ora or
# /etc/tnsnames.ora.  Alternatively set the TNS_ADMIN environment
# variable and put the file in $TNS_ADMIN/tnsnames.ora.
#
# The administrative user for cloud databases is ADMIN and the administrative
# user for on premises databases is SYSTEM.
#------------------------------------------------------------------------------

import getpass
import os
import sys

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
    env_name = "PYO_SAMPLES_" + name
    value = os.environ.get(env_name)
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
    return get_value("MAIN_USER", "Main User Name", DEFAULT_MAIN_USER)

def get_main_password():
    return get_value("MAIN_PASSWORD", "Password for %s" % get_main_user(),
                     password=True)

def get_edition_user():
    return get_value("EDITION_USER", "Edition User Name", DEFAULT_EDITION_USER)

def get_edition_password():
    return get_value("EDITION_PASSWORD",
                     "Password for %s" % get_edition_user(), password=True)

def get_edition_name():
    return get_value("EDITION_NAME", "Edition Name", DEFAULT_EDITION_NAME)

def get_connect_string():
    return get_value("CONNECT_STRING", "Connect String",
                     DEFAULT_CONNECT_STRING)

def get_main_connect_string(password=None):
    if password is None:
        password = get_main_password()
    return "%s/%s@%s" % (get_main_user(), password, get_connect_string())

def get_driver_mode():
    return get_value("DRIVER_MODE", "Driver mode (thin|thick)", "thin")

def get_is_thin():
    return get_driver_mode() == "thin"

def get_drcp_connect_string():
    connect_string = get_value("DRCP_CONNECT_STRING", "DRCP Connect String",
                               DEFAULT_DRCP_CONNECT_STRING)
    return "%s/%s@%s" % (get_main_user(), get_main_password(), connect_string)

def get_edition_connect_string():
    return "%s/%s@%s" % \
            (get_edition_user(), get_edition_password(), get_connect_string())

def get_admin_connect_string():
    admin_user = get_value("ADMIN_USER", "Administrative user", "admin")
    admin_password = get_value("ADMIN_PASSWORD", f"Password for {admin_user}", password=True)
    return "%s/%s@%s" % (admin_user, admin_password, get_connect_string())

def get_oracle_client():
    if sys.platform in ("darwin", "win32"):
        return get_value("ORACLE_CLIENT_PATH", "Oracle Instant Client Path")

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
