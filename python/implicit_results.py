#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# implicit_results.py
#   This script demonstrates the use of the 12.1 feature that allows PL/SQL
# procedures to return result sets implicitly, without having to explicitly
# define them.
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())
cursor = connection.cursor()

# use PL/SQL block to return two cursors
cursor.execute("""
        declare
            c1 sys_refcursor;
            c2 sys_refcursor;
        begin

            open c1 for
            select * from TestNumbers;

            dbms_sql.return_result(c1);

            open c2 for
            select * from TestStrings;

            dbms_sql.return_result(c2);

        end;""")

# display results
for ix, result_set in enumerate(cursor.getimplicitresults()):
    print("Result Set #" + str(ix + 1))
    for row in result_set:
        print(row)
    print()
