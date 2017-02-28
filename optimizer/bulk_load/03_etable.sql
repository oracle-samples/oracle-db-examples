--
-- This script creates an external table.
-- The "dirs" script must be run first because
-- the directories are referenced.
--
DROP TABLE sales_ext
/

--
-- I like to specify the character set explicitly
-- because the external table would otherwise 
-- inherit the characterset of the database and use
-- this when reading the datafiles. I prefer a fixed
-- width character set as it enables inter-file 
-- parallism in both 11g and 12c.
--
CREATE TABLE sales_ext (
  id  NUMBER
, txt CHAR(100))
ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
 DEFAULT DIRECTORY data_dir
 ACCESS PARAMETERS
 ( RECORDS DELIMITED BY NEWLINE
   CHARACTERSET US7ASCII
   BADFILE bad_dir: 'sales%a_%p.bad'
   LOGFILE log_dir: 'sales%a_%p.log'
   FIELDS TERMINATED BY '|'
   MISSING FIELD VALUES ARE NULL )
LOCATION ( data_dir:'sales_1.dat',
           data_dir:'sales_2.dat' ))
PARALLEL
REJECT LIMIT 10;
