#! /usr/bin/env python

#------------------------------------------------------------------------------
# Copyright (c) 2022, Oracle and/or its affiliates.
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
# sqlp.py
#
# USAGE
#  python sqlp.py [username@password/connect_string]
#
# DESCRIPTION
#  Example interactive command line SQL executor for ad hoc statements.
#
#  This is modelled on SQL*Plus but has MANY differences.  Some are:
#   - It always reads from the keyboard and doesn't directly read SQL files
#   - It doesn't execute SQL*Plus-specific commands like SET or DESC
#   - It doesn't support "&" substitution or bind variables
#   - It doesn't display all data types, e.g. Oracle types aren't supported
#   - It doesn't do smart sizing or wrapping of query columns
#   - Statements like "CREATE OR REPLACE" must have all keywords on the same
#     (first) line
#   - it has very limited error handling
#------------------------------------------------------------------------------

import oracledb
import getpass
import sys
import re
import os
import signal

# Statement types
STMT_TYPE_UNKNOWN = 0
STMT_TYPE_SQL     = 1 # Like SELECT or INSERT
STMT_TYPE_PLSQL   = 2 # Like BEGIN or CREATE FUNCTION
STMT_TYPE_SQLPLUS = 3 # Like SET or DESC

# Simple regexps for statement type identification
SQL_PATTERN = re.compile(
    r'^(administer|alter|analyze|associate|audit|call|comment|commit|create'
    '|delete|disassociate|drop|explain|flashback|grant|insert|lock|merge'
    '|noaudit|purge|rename|revoke|rollback|savepoint|select|truncate|update'
    '|with|set\s+constraint[s*]|set\s+role|set\s+transaction)(\s|$|;)',
    re.IGNORECASE)

PLSQL_PATTERN = re.compile(
    r'^(begin|declare|create\s+or\s+replace|create\s+function'
    '|create\s+procedure|create\s+package|create\s+type)(\s|$)',
    re.IGNORECASE)

SQLPLUS_PATTERN = re.compile(
    r'^(@|@@|(acc(e?|ep?|ept?))|(a(p?|pp?|ppe?|ppen?|ppend?))|(archive\s+log)'
    '|(attr(i?|ib?|ibu?|ibut?|ibute?))|(bre(a?|ak?))|(bti(t?|tl?|tle?))'
    '|(c(h?|ha?|han?|hang?|hange?))|(cl(e?|ea?|ear?))|(col(u?|um?|umn?))'
    '|(comp(u?|ut?|ute?))|(conn(e?|ec?|ect?))|copy|(def(i?|in?|ine?))|del'
    '|(desc(r?|ri?|rib?|ribe?))|(disc(o?|on?|onn?|onne?|onnec?|onnect?))'
    '|(ed(i?|it?))|(exec(u?|ut?|ute?))|exit|get|help|history|host'
    '|(i(n?|np?|npu?|nput?))|(l(i?|is?|ist?))|(passw(o?|or?|ord?))'
    '|(pau(s?|se?))|print|(pro(m?|mp?|mpt?))|quit|recover|(rem(a?|ar?|ark?))'
    '|(repf(o?|oo?|oot?|oote?|ooter?))|(reph(e?|ea?|ead?|eade?|eader?))'
    '|(r(u?|un?))|(sav(e?))|set|(sho(w?))|shutdown|(spo(o?|ol?))|(sta(r?|rt?))'
    '|startup|store|(timi(n?|ng?))|(tti(t?|tl?|tle?))|(undef(i?|in?|ine?))'
    '|(var(i?|ia?|iab?|iabl?|iable?))|whenever|xquery|--.*)(\s|$)',
    re.IGNORECASE)

QUERY_PATTERN = re.compile(r'(select|with)\s*', re.IGNORECASE)

# Look up the first keywords to find the statement type
def detect_statement_type(s):
    if PLSQL_PATTERN.match(s):
        return STMT_TYPE_PLSQL
    elif SQL_PATTERN.match(s):
        return STMT_TYPE_SQL
    elif SQLPLUS_PATTERN.match(s):
        return STMT_TYPE_SQLPLUS
    else:
        return STMT_TYPE_UNKNOWN

# Read text until the expected end-of-statement terminator is seen.
#
#   - SQL*Plus commands like SET or DESC can have an optional semi-colon
#     statement terminator.
#
#   - SQL commands like SELECT and INSERT can end with a semi-colon or with a
#     slash on a new line.
#
#   - PL/SQL commands like BEGIN or CREATE PROCEDURE must end with a slash on a
#     new line.
#
def read_statement():
    statement = ''
    statement_type = STMT_TYPE_UNKNOWN
    line_number = 1
    print('SQLP> ', end='')
    while True:
        try:
            line = input().strip()
        except EOFError:
            sys.exit(0)
        line_number += 1
        if len(line) == 0 and statement_type != STMT_TYPE_PLSQL:
            statement = ''
            break
        if statement_type == STMT_TYPE_UNKNOWN:
            statement_type = detect_statement_type(line)
        if statement_type == STMT_TYPE_UNKNOWN:
            return(line, STMT_TYPE_UNKNOWN)
        elif (line == '/'
            and (statement_type == STMT_TYPE_SQL
                 or statement_type == STMT_TYPE_PLSQL)):
            break
        elif ((statement_type == STMT_TYPE_SQL
               or statement_type == STMT_TYPE_SQLPLUS)
              and line[-1] == ';'):
            statement = f'{statement} {line[:-1]}' if statement else line[:-1]
            break
        elif statement_type == STMT_TYPE_SQLPLUS:
            statement = line
            break
        else:
            statement = f'{statement} {line}' if statement else line

        print('{0:3}  '.format(line_number), end='')

    return(statement, statement_type)

# Execute a statement that needs to be sent to the database
def execute_db_statement(connection, statement, statement_type):
    if not connection:
        print('Not connected')
    else:
        with connection.cursor() as cursor:
            try:
                cursor.execute(statement)
                if (statement_type == STMT_TYPE_SQL
                    and QUERY_PATTERN.match(statement)):
                    fetch_rows(cursor)
            except oracledb.Error as e:
                error, = e.args
                print(statement)
                print('*'.rjust(error.offset+1, ' '))
                print(error.message)

# Handle "local" SQL*Plus commands
def execute_sqlplus_statement(connection, statement):
    if re.match(r'(conn(e?|ec?|ect?))(\s|$)', statement):
        a = re.split(r'\s+', statement)
        dsn = None if len(a) <= 1 else a[1]
        connection = get_connection(dsn)
    elif (statement.lower().strip() == 'exit'
        or statement.lower().strip() == 'quit'):
        sys.exit(0)
    elif (re.match(r'(rem(a?|ar?|ark?))(\s|$)', statement)
          or statement[:2] == '--'):
        return connection
    #elif ...
    #  This is where you can extend keyword support
    else:
        print('Unsupported SQL*Plus command "{}"'.
              format(re.split(r'\s+', statement)[0]))
    return connection

# Fetch and display query rows
def fetch_rows(cursor):
    try:
        rows = cursor.fetchmany()
        if not rows:
            print('no rows selected')
        else:
            col_formats = get_col_formats(cursor.description)
            print_headings(col_formats)
            while rows:
                for row in rows:
                    print_row(col_formats, row)
                rows = cursor.fetchmany()
    except oracledb.Error as e:
        error, = e.args
        print(error.message)

# Naive logic to choose column display widths
def get_col_formats(description):
    col_formats = []
    for col in description:
        if col[2] == None:  # no width, e.g. a LOB
            w = len(col[0]) # use heading length
        elif col[1] == oracledb.DB_TYPE_NUMBER:
            w = max(40, len(col[0]))
        else:
            w = max(col[2], len(col[0]))
        col_formats.append({'heading': col[0], 'type': col[1], 'width': w})
    return col_formats

# Print query column headings and separator
def print_headings(col_formats):
    for col in col_formats:
        print('{h:{w}s}'.format(h=col['heading'], w=col['width']), end=' ')
    print()
    for col in col_formats:
        print('-'.rjust(col['width'], '-'), end=' ')
    print()

# Print a row of query data
# No column wrapping occurs
def print_row(col_formats, row):
    for i, v in enumerate(row):
        v = ' ' if v == None else v
        print('{v:{w}s}'.format(v=str(v), w=col_formats[i]['width']), end=' ')
    print()

# Connect
def get_connection(dsn=None):
    connection = None
    try:
        if dsn:
            connection = oracledb.connect(dsn=dsn)
        else:
            un = get_user()
            pw = get_password()
            cs = get_connect_string()
            if un and pw and cs:
                connection = oracledb.connect(user=un, password=pw, dsn=cs)
            else:
                raise ValueError('Invalid credentials entered')
    except ValueError as e:
        print(e)
    except oracledb.Error as e:
        error, = e.args
        print('Failed to connect')
        print(error.message)
    finally:
        return connection

# Signal handler for graceful interrupts
def signal_handler(sig, frame):
    print()
    sys.exit(0)

# Connection helper functions
def get_user():
    return input('Enter username: ').strip()

def get_password():
    return getpass.getpass('Enter password: ')

def get_connect_string():
    return input('Enter connection string: ')

# Main body
if __name__ == '__main__':

    # Allow graceful interrupts
    signal.signal(signal.SIGINT, signal_handler)

    # Fetch LOBs directly as strings or bytes
    oracledb.defaults.fetch_lobs = False

    # Fetch numbers as decimal.Decimal
    oracledb.defaults.fetch_decimals = True

    # Connect
    connection = None if len(sys.argv) <= 1 else get_connection(sys.argv[1])

    # Loop to read statements and execute them
    while True:
        (statement, statement_type) = read_statement()
        if len(statement) == 0:
            continue
        elif statement_type == STMT_TYPE_UNKNOWN:
            print('Unknown command "{}"'. format(re.split(r'\s+', statement)[0]))
        elif statement_type == STMT_TYPE_SQLPLUS:
            connection = execute_sqlplus_statement(connection, statement)
        else:
            execute_db_statement(connection, statement, statement_type)
