--From: nicole.alexander@oracle.com--
/************************************************************/
/* DATABASE INFO  12c R2                                          */
/************************************************************/
-- host: nshga08.us.oracle.com
-- port: 1522
-- system: system/spatial@pdborcl12c
-- service: pdborcl12c.us.oracle.com
-- user: odf_eu_q312/odf_eu_q312@pdborcl12c
-- user: odf_na_q312/odf_na_q312@pdborcl12c

/*********************************************************/
/*These are sample queries currently used by the geocoder */
/**********************************************************/

SELECT a.REAL_NAME 
FROM "ODF_NA_Q312"."GC_AREA_NVT" a, "ODF_NA_Q312"."GC_AREA_NVT" b  
WHERE a.country_code_2='US' AND a.admin_level IN (3,4) AND a.area_name='SAN FRANCISCO' 
AND a.level2_area_id=b.area_id AND b.country_code_2='US' AND b.admin_level=2 AND b.area_name='CA';

SELECT REAL_NAME 
FROM "ODF_NA_Q312"."GC_AREA_NVT" 
WHERE country_code_2='US' AND admin_level IN (3,4) AND area_name='SAN FRANCISCO';

---------------------------------------------------------------------------------

SELECT /*+ INDEX(a, IDX_NVT_ROAD_MUNBN) */ name, base_name
FROM odf_eu_q312.GC_ROAD_NVT a 
WHERE municipality_id=20126290 AND partition_id=100012 AND COUNTRY_CODE_2='IT' AND base_name = 'MARCONI';

SELECT /*+ INDEX(a, IDX_NVT_ROAD_MUNBNSD) */ name, base_name
FROM odf_eu_q312.GC_ROAD_NVT a WHERE
municipality_id=20126290 AND partition_id=100012 AND COUNTRY_CODE_2='IT' AND soundex(base_name)=soundex('MARCONI');

--Elapsed: 00:00:00.01 -- 40 rows



/********************CONTEXT INDEX*****************************/
/* USING FUZZY+SOUNDEX+STEM; DATASET ODF_EU_Q312                          */
/***********************************************************/

-- Too slow; But the result set is ideal --

DROP INDEX rdcindex;
DROP INDEX bname_cidx;
CREATE INDEX rdcindex ON gc_road_nvt(base_name) INDEXTYPE IS CTXSYS.CONTEXT
FILTER BY municipality_id, partition_id, country_code_2
/

SELECT * FROM
(SELECT  /*+ FIRST_ROWS */ name, base_name, score(1)
FROM odf_eu_q312.GC_ROAD_NVT a WHERE
municipality_id=20126290 AND partition_id=100012 AND COUNTRY_CODE_2='IT' AND 
CONTAINS(a.base_name,'(MARCONI) OR !MARCONI OR fuzzy(MARCONI,,10, weight) OR $MARCONI',1) > 0
ORDER BY score(1) DESC) 
WHERE SCORE(1) >70;

--Elapsed: 00:00:10.98 -- 10 rows



/********************BASE_NAME****************************************/
/* NDATA on base_name; DATASET ODF_EU_Q312
/*********************************************************************/

-- Much faster; But way too many results! --

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
WHERE CONTAINS(base_name,  'ndata( base_name, MARCONI) ',1)>0
ORDER BY score(1) DESC)
WHERE score(1) > 70;

--Elapsed: 00:00:02.18; 12805 rows selected--

--Q1: Is there some way to get the result set closer to SOUNDEX+FUZZY+STEM?
--Q2: Any suggestions for additional tuning?


/********************AREA_NAME****************************************/
/* NDATA on area_name; DATASET ODF_NA_Q312
/*********************************************************************/

-- Works well on area_names. 

EXEC ctx_ddl.drop_preference('aname_ds')
BEGIN
  ctx_ddl.create_preference('aname_ds', 'MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('aname_ds', 'COLUMNS', 'area_name');
END;
/

EXEC ctx_ddl.drop_section_group('aname_sg');
BEGIN
  ctx_ddl.create_section_group('aname_sg', 'BASIC_SECTION_GROUP');
  ctx_ddl.add_ndata_section('aname_sg', 'area_name', 'area_name');
END;
/

EXEC ctx_ddl.drop_preference('aname_wl');
BEGIN
  ctx_ddl.create_preference('aname_wl', 'BASIC_WORDLIST');
  ctx_ddl.set_attribute('aname_wl', 'NDATA_ALTERNATE_SPELLING', 'TRUE');
  ctx_ddl.set_attribute('aname_wl', 'NDATA_BASE_LETTER', 'TRUE'); 
--  ctx_ddl.set_attribute('aname_wl','FUZZY_MATCH','AUTO');
--  ctx_ddl.set_attribute('aname_wl','FUZZY_SCORE','70');
--  ctx_ddl.set_attribute('aname_wl','FUZZY_NUMRESULTS','20');
--  ctx_ddl.set_attribute('aname_wl','SUBSTRING_INDEX','FALSE');
--  ctx_ddl.set_attribute('aname_wl','STEMMER','AUTO');
--  ctx_ddl.set_attribute('aname_wl','PREFIX_INDEX','FALSE');
--  ctx_ddl.set_attribute('aname_wl','PREFIX_MIN_LENGTH',3);
--  ctx_ddl.set_attribute('aname_wl','PREFIX_MAX_LENGTH', 4);
END;
/
 
DROP INDEX aname_cidx;
CREATE INDEX aname_cidx ON gc_area_nvt(area_name) INDEXTYPE IS ctxsys.context
FILTER BY municipality_id, partition_id, country_code_2
parameters ('datastore aname_ds section group aname_sg wordlist aname_wl');

SELECT * FROM
(SELECT /*+ FIRST_ROWS */ real_name, area_name, score(1)
FROM "ODF_NA_Q312"."GC_AREA_NVT" 
WHERE country_code_2='US' AND admin_level IN (3,4) AND
CONTAINS(area_name,  'ndata(area_name, ''SAN FRANCESCO'', order) ',1)>0
ORDER BY score(1) DESC)
WHERE score(1) > 70;

SELECT * FROM
(SELECT /*+ FIRST_ROWS */ real_name, area_name, score(1)
FROM "ODF_NA_Q312"."GC_AREA_NVT" 
WHERE country_code_2='US' AND admin_level IN (3,4) AND
CONTAINS(area_name,  'ndata(area_name, ''RED WOOD SHORE'', order) ',1)>0
ORDER BY score(1) DESC)
WHERE score(1) > 70;

--Q1. Any suggestions for additional tuning?


/************* THANK YOU ***************/


 


SELECT * FROM
(SELECT  /*+ FIRST_ROWS */ name, base_name, score(1)
FROM odf_eu_q312.GC_ROAD_NVT a WHERE
municipality_id=20126290 AND partition_id=100012 AND COUNTRY_CODE_2='IT' AND 
CONTAINS(a.base_name,'(MARCCONI) OR !MARCCONI OR fuzzy(MARCCONI,,10, weight) OR $MARCCONI',1) > 0
ORDER BY score(1) DESC) 
WHERE SCORE(1) >70;

SELECT * FROM 
(SELECT /*+ FIRST_ROWS */name, base_name, score(1)
FROM odf_eu_q312.GC_ROAD_NVT a WHERE
municipality_id=20126290 AND partition_id=100012 AND COUNTRY_CODE_2='IT' AND 
CONTAINS(a.base_name, '
<QUERY>
  <TEXTQUERY>
    <PROGRESSION>
      <SEQ>MARCONI</SEQ>
      <SEQ>$MARCONI</SEQ>
      <SEQ>fuzzy(MARCONI,,10, weight)</SEQ>
      <SEQ>!MARCONI</SEQ>
    </PROGRESSION>
  </TEXTQUERY>
</QUERY>
', 1) > 0
ORDER BY score(1) DESC)
WHERE ROWNUM < 11;

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

