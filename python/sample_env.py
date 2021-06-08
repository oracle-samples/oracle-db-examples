#------------------------------------------------------------------------------
# Copyright (c) 2017, 2020, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Sets the environment used by most Python cx_Oracle samples. Production
# applications should consider using External Authentication to
# avoid hard coded credentials.
#
# You can set values in environment variables to bypass the sample requesting
# the information it requires.
#
#     CX_ORACLE_SAMPLES_MAIN_USER: user used for most samples
#     CX_ORACLE_SAMPLES_MAIN_PASSWORD: password of user used for most samples
#     CX_ORACLE_SAMPLES_EDITION_USER: user for editioning
#     CX_ORACLE_SAMPLES_EDITION_PASSWORD: password of user for editioning
#     CX_ORACLE_SAMPLES_EDITION_NAME: name of edition for editioning
#     CX_ORACLE_SAMPLES_CONNECT_STRING: connect string
#     CX_ORACLE_SAMPLES_DRCP_CONNECT_STRING: DRCP connect string
#     CX_ORACLE_SAMPLES_ADMIN_USER: admin user for setting up samples
#     CX_ORACLE_SAMPLES_ADMIN_PASSWORD: admin password for setting up samples
#
# CX_ORACLE_SAMPLES_CONNECT_STRING can be set to an Easy Connect string, or a
# Net Service Name from a tnsnames.ora file or external naming service,
# or it can be the name of a local Oracle database instance.
#
# If cx_Oracle is using Instant Client, then an Easy Connect string is
# generally appropriate. The syntax is:
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

def get_value(name, label, default_value=""):
    value = PARAMETERS.get(name)
    if value is not None:
        return value
    env_name = "CX_ORACLE_SAMPLES_" + name
    value = os.environ.get(env_name)
    if value is None:
        if default_value:
            label += " [%s]" % default_value
        label += ": "
        if default_value:
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
    return get_value("MAIN_PASSWORD", "Password for %s" % get_main_user())

def get_edition_user():
    return get_value("EDITION_USER", "Edition User Name", DEFAULT_EDITION_USER)

def get_edition_password():
    return get_value("EDITION_PASSWORD",
                     "Password for %s" % get_edition_user())

def get_edition_name():
    return get_value("EDITION_NAME", "Edition Name", DEFAULT_EDITION_NAME)

def get_connect_string():
    return get_value("CONNECT_STRING", "Connect String",
                     DEFAULT_CONNECT_STRING)

def get_main_connect_string(password=None):
    if password is None:
        password = get_main_password()
    return "%s/%s@%s" % (get_main_user(), password, get_connect_string())

def get_drcp_connect_string():
    connect_string = get_value("DRCP_CONNECT_STRING", "DRCP Connect String",
                               DEFAULT_DRCP_CONNECT_STRING)
    return "%s/%s@%s" % (get_main_user(), get_main_password(), connect_string)

def get_edition_connect_string():
    return "%s/%s@%s" % \
            (get_edition_user(), get_edition_password(), get_connect_string())

def get_admin_connect_string():
    admin_user = get_value("ADMIN_USER", "Administrative user", "admin")
    admin_password = get_value("ADMIN_PASSWORD", "Password for %s" % admin_user)
    return "%s/%s@%s" % (admin_user, admin_password, get_connect_string())

def run_sql_script(conn, script_name, **kwargs):
    statement_parts = []
    cursor = conn.cursor()
    replace_values = [("&" + k + ".", v) for k, v in kwargs.items()] + \
                     [("&" + k, v) for k, v in kwargs.items()]
    script_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
    file_name = os.path.join(script_dir, "sql", script_name + "_exec.sql")
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
