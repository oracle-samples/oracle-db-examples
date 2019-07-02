#------------------------------------------------------------------------------
# Copyright (c) 2017, 2019, Oracle and/or its affiliates. All rights reserved.
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
#     CX_ORACLE_SAMPLES_SYSDBA_USER: SYSDBA user for setting up samples
#     CX_ORACLE_SAMPLES_SYSDBA_PASSWORD: SYSDBA password for setting up samples
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
# e.g. "localhost/orclpdb" or "localhost/XE"
#
# If using a tnsnames.ora file, the file can be in a default
# location such as $ORACLE_HOME/network/admin/tnsnames.ora or
# /etc/tnsnames.ora.  Alternatively set the TNS_ADMIN environment
# variable and put the file in $TNS_ADMIN/tnsnames.ora.
#------------------------------------------------------------------------------

from __future__ import print_function

import getpass
import os
import sys

# for Python 2.7 we need raw_input
try:
    input = raw_input
except NameError:
    pass

# default values
DEFAULT_MAIN_USER = "pythondemo"
DEFAULT_EDITION_USER = "pythoneditions"
DEFAULT_EDITION_NAME = "python_e1"
DEFAULT_CONNECT_STRING = "localhost/orclpdb"

# dictionary containing all parameters; these are acquired as needed by the
# methods below (which should be used instead of consulting this dictionary
# directly) and then stored so that a value is not requested more than once
PARAMETERS = {}

def GetValue(name, label, defaultValue=""):
    value = PARAMETERS.get(name)
    if value is not None:
        return value
    envName = "CX_ORACLE_SAMPLES_" + name
    value = os.environ.get(envName)
    if value is None:
        if defaultValue:
            label += " [%s]" % defaultValue
        label += ": "
        if defaultValue:
            value = input(label).strip()
        else:
            value = getpass.getpass(label)
        if not value:
            value = defaultValue
    PARAMETERS[name] = value
    return value

def GetMainUser():
    return GetValue("MAIN_USER", "Main User Name", DEFAULT_MAIN_USER)

def GetMainPassword():
    return GetValue("MAIN_PASSWORD", "Password for %s" % GetMainUser())

def GetEditionUser():
    return GetValue("EDITION_USER", "Edition User Name", DEFAULT_EDITION_USER)

def GetEditionPassword():
    return GetValue("EDITION_PASSWORD", "Password for %s" % GetEditionUser())

def GetEditionName():
    return GetValue("EDITION_NAME", "Edition Name", DEFAULT_EDITION_NAME)

def GetConnectString():
    return GetValue("CONNECT_STRING", "Connect String", DEFAULT_CONNECT_STRING)

def GetMainConnectString(password=None):
    if password is None:
        password = GetMainPassword()
    return "%s/%s@%s" % (GetMainUser(), password, GetConnectString())

def GetDrcpConnectString():
    return GetMainConnectString() + ":pooled"

def GetEditionConnectString():
    return "%s/%s@%s" % \
            (GetEditionUser(), GetEditionPassword(), GetConnectString())

def GetSysdbaConnectString():
    sysdbaUser = GetValue("SYSDBA_USER", "SYSDBA user", "sys")
    sysdbaPassword = GetValue("SYSDBA_PASSWORD",
            "Password for %s" % sysdbaUser)
    return "%s/%s@%s" % (sysdbaUser, sysdbaPassword, GetConnectString())

def RunSqlScript(conn, scriptName, **kwargs):
    statementParts = []
    cursor = conn.cursor()
    replaceValues = [("&" + k + ".", v) for k, v in kwargs.items()] + \
            [("&" + k, v) for k, v in kwargs.items()]
    scriptDir = os.path.dirname(os.path.abspath(sys.argv[0]))
    fileName = os.path.join(scriptDir, "sql", scriptName + "Exec.sql")
    for line in open(fileName):
        if line.strip() == "/":
            statement = "".join(statementParts).strip()
            if statement:
                for searchValue, replaceValue in replaceValues:
                    statement = statement.replace(searchValue, replaceValue)
                cursor.execute(statement)
            statementParts = []
        else:
            statementParts.append(line)
    cursor.execute("""
            select name, type, line, position, text
            from dba_errors
            where owner = upper(:owner)
            order by name, type, line, position""",
            owner = GetMainUser())
    prevName = prevObjType = None
    for name, objType, lineNum, position, text in cursor:
        if name != prevName or objType != prevObjType:
            print("%s (%s)" % (name, objType))
            prevName = name
            prevObjType = objType
        print("    %s/%s %s" % (lineNum, position, text))

