/*-----------------------------------------------------------------------------
 * Copyright 2017, 2019, Oracle and/or its affiliates. All rights reserved.
 *---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------
 * DropSamplesExec.sql
 *   This script performs the actual work of dropping the database schemas and
 * edition used by the cx_Oracle samples. It is called by the DropSamples.sql
 * and SetupSamples.sql files after acquiring the necessary parameters and
 * also by the Python script DropSamples.py.
 *---------------------------------------------------------------------------*/

begin

    for r in
            ( select username
              from dba_users
              where username in (upper('&main_user'), upper('&edition_user'))
            ) loop
        execute immediate 'drop user ' || r.username || ' cascade';
    end loop;

    for r in
            ( select edition_name
              from dba_editions
              where edition_name in (upper('&edition_name'))
            ) loop
        execute immediate 'drop edition ' || r.edition_name || ' cascade';
    end loop;

end;
/

