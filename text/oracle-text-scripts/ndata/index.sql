EXEC ctx_ddl.drop_preference('bname_ds')
BEGIN
  ctx_ddl.create_preference('bname_ds', 'MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('bname_ds', 'COLUMNS', 'base_name');
END;
/

EXEC ctx_ddl.drop_section_group('bname_sg');
BEGIN
  ctx_ddl.create_section_group('bname_sg', 'BASIC_SECTION_GROUP');
  ctx_ddl.add_ndata_section('bname_sg', 'base_name', 'base_name');
END;
/

EXEC ctx_ddl.drop_preference('bname_wl');
BEGIN
  ctx_ddl.create_preference('bname_wl', 'BASIC_WORDLIST');
  ctx_ddl.set_attribute('bname_wl', 'NDATA_ALTERNATE_SPELLING', 'FALSE');
  ctx_ddl.set_attribute('bname_wl', 'NDATA_BASE_LETTER', 'TRUE');
--  ctx_ddl.set_attribute('bname_wl','FUZZY_MATCH','AUTO');
--  ctx_ddl.set_attribute('bname_wl','FUZZY_SCORE','70');
--  ctx_ddl.set_attribute('bname_wl','FUZZY_NUMRESULTS','20');
--  ctx_ddl.set_attribute('bname_wl','SUBSTRING_INDEX','TRUE');
--  ctx_ddl.set_attribute('bname_wl','STEMMER','AUTO');
--  ctx_ddl.set_attribute('bname_wl','PREFIX_INDEX','TRUE');
--  ctx_ddl.set_attribute('bname_wl','PREFIX_MIN_LENGTH',3);
--  ctx_ddl.set_attribute('bname_wl','PREFIX_MAX_LENGTH', 4);
END;
/
 
DROP INDEX rdcindex;
DROP INDEX bname_cidx;
CREATE INDEX bname_cidx ON gc_road_nvt(base_name) INDEXTYPE IS ctxsys.context
FILTER BY municipality_id, partition_id, country_code_2
parameters ('datastore bname_ds section group bname_sg wordlist bname_wl');

SELECT * FROM
(SELECT /*+ FIRST_ROWS */ name, base_name, score(1)
FROM gc_road_nvt
WHERE municipality_id=20126290 AND partition_id=100012 AND COUNTRY_CODE_2='IT' AND 
CONTAINS(base_name,  'ndata( base_name, MARCONI) ',1)>0
ORDER BY score(1) DESC)
WHERE score(1) > 80;
