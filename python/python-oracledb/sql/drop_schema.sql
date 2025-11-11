/*-----------------------------------------------------------------------------
 * Copyright 2017, 2025, Oracle and/or its affiliates.
 *
 * This software is dual-licensed to you under the Universal Permissive License
 * (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
 * 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
 * either license.*
 *
 * If you elect to accept the software under the Apache License, Version 2.0,
 * the following applies:
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *---------------------------------------------------------------------------*/

/*-----------------------------------------------------------------------------
 * drop_schema.sql
 *
 * Performs the actual work of dropping the database schemas and edition used
 * by the python-oracledb samples. It is executed by the Python script
 * drop_schema.py.
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
	          start with edition_name = upper('&edition_name')
	          connect by prior edition_name = parent_edition_name
	          order by level desc
            ) loop
        execute immediate 'drop edition ' || r.edition_name || ' cascade';
    end loop;

end;
/
