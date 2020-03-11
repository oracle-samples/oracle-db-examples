-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   Setup - Grants Privileges to Users - dmshgrants.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
--
--
-- dmshgrants.sql
--
-- Copyright (c) 2001, 2010, Oracle and/or its affiliates. 
-- All rights reserved. 
--
--    NAME
--    dmshgrants.sql
--
--    DESCRIPTION
--      This script grants SELECT on SH tables and SYS privileges 
--      required to run the Oracle Data Mining demo programs
--      
--      The script is to be run in SYS account
--
--    NOTES
--       &&1    Name of the DM user
--
--------------------------------------------------------------------------------
DEFINE DMUSER = &&1 

grant create session to &DMUSER
/
grant create table to &DMUSER
/
grant create view to &DMUSER
/
grant create mining model to &DMUSER
/
grant execute on ctxsys.ctx_ddl to &DMUSER
/

GRANT SELECT ON sh.customers TO &DMUSER
/
GRANT SELECT ON sh.sales TO &DMUSER
/
GRANT SELECT ON sh.products TO &DMUSER
/
GRANT SELECT ON sh.supplementary_demographics TO &DMUSER
/
GRANT SELECT ON sh.countries TO &DMUSER
/ 
