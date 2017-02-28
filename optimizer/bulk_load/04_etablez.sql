--
-- This script creates an external table with a 
-- preprocessor script called "unc.sh". In this case 
-- the pre-processor will gunzip the data files 
-- on-the-fly as they are loaded.
-- The "dirs" script must be run first because
-- the directories are referenced.
--
DROP TABLE salesz_ext
/

CREATE TABLE salesz_ext (
  id  NUMBER
, txt CHAR(100))
ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
 DEFAULT DIRECTORY data_dir
 ACCESS PARAMETERS
 ( RECORDS DELIMITED BY NEWLINE
   PREPROCESSOR data_dir:'unc.sh' 
   CHARACTERSET US7ASCII
   BADFILE bad_dir: 'salesz%a_%p.bad'
   LOGFILE log_dir: 'salesz%a_%p.log'
   FIELDS TERMINATED BY '|'
   MISSING FIELD VALUES ARE NULL )
LOCATION ( data_dir:'sales_1.dat.gz',
           data_dir:'sales_2.dat.gz' ))
PARALLEL
REJECT LIMIT 10;
