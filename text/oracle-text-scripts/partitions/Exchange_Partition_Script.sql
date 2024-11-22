--Table Creation:
-----------------
drop table xcd_sample_dmy_t;

drop table xcd_sample_xml_t;

drop table xcd_tmp_dmy_t;

drop table xcd_tmp_xml_t;


CREATE TABLE xcd_sample_dmy_t
  (
    ENTY_ID      NUMBER,
    ENTY_TYP_MNM VARCHAR2(10),
    DUMMY       VARCHAR2(1),
    RGN_ID      NUMBER,
    CONSTRAINT XCD_SMP_DMY_PK_IDX PRIMARY KEY (ENTY_ID, ENTY_TYP_MNM)
  )
   PARTITION BY RANGE(RGN_ID)
  (
    PARTITION PART_XCD_4 VALUES LESS THAN (5),
    PARTITION PART_XCD_5 VALUES LESS THAN (6),
    PARTITION PART_XCD_6 VALUES LESS THAN (7),
    PARTITION PART_XCD_7 VALUES LESS THAN (8));


CREATE TABLE xcd_sample_xml_t
  (
    ENTY_ID      NUMBER,
    ENTY_TYP_MNM VARCHAR2(10),
    TXT_SRCH_XML SYS.XMLTYPE ,
    SEQ    NUMBER,
    RGN_ID NUMBER,
    CONSTRAINT XCD_SMP_XML_PK_IDX PRIMARY KEY (ENTY_ID, ENTY_TYP_MNM)
  )
   PARTITION BY RANGE(RGN_ID)
  (
    PARTITION PART_XCD_4 VALUES LESS THAN (5),
    PARTITION PART_XCD_5 VALUES LESS THAN (6),
    PARTITION PART_XCD_6 VALUES LESS THAN (7),
    PARTITION PART_XCD_7 VALUES LESS THAN (8));


CREATE TABLE xcd_tmp_dmy_t
  (
    ENTY_ID      NUMBER,
    ENTY_TYP_MNM VARCHAR2(10),
    DUMMY       VARCHAR2(1),
    RGN_ID      NUMBER,
    CONSTRAINT XCD_TMP_DMY_PK_IDX PRIMARY KEY (ENTY_ID, ENTY_TYP_MNM)
  );


CREATE TABLE xcd_tmp_xml_t
  (
    ENTY_ID      NUMBER,
    ENTY_TYP_MNM VARCHAR2(10),
    TXT_SRCH_XML SYS.XMLTYPE ,
    SEQ    NUMBER,
    RGN_ID NUMBER,
    CONSTRAINT XCD_TMP_XML_PK_IDX PRIMARY KEY (ENTY_ID, ENTY_TYP_MNM)
  );


--Preference:
-------------

BEGIN
ctx_ddl.create_preference('xcd_LEXER_pref', 'BASIC_LEXER');
ctx_ddl.create_preference('xcd_word_pref', 'BASIC_WORDLIST');
ctx_ddl.set_attribute('xcd_word_pref','SUBSTRING_INDEX','TRUE');
END;
/

BEGIN
ctx_ddl.create_preference('xcd_tmp_store_pref', 'DETAIL_DATASTORE');
ctx_ddl.set_attribute('xcd_tmp_store_pref', 'binary', 'true');
ctx_ddl.set_attribute('xcd_tmp_store_pref', 'detail_table', 'xcd_tmp_xml_t');
ctx_ddl.set_attribute('xcd_tmp_store_pref', 'detail_key', 'enty_id,enty_typ_mnm');
ctx_ddl.set_attribute('xcd_tmp_store_pref', 'detail_lineno', 'seq');
ctx_ddl.set_attribute('xcd_tmp_store_pref', 'detail_text', 'txt_srch_xml');
END;
/

BEGIN
ctx_ddl.create_preference('xcd_smpl_store_pref', 'DETAIL_DATASTORE');
ctx_ddl.set_attribute('xcd_smpl_store_pref', 'binary', 'true');
ctx_ddl.set_attribute('xcd_smpl_store_pref', 'detail_table', 'xcd_sample_xml_t');
ctx_ddl.set_attribute('xcd_smpl_store_pref', 'detail_key', 'enty_id,enty_typ_mnm');
ctx_ddl.set_attribute('xcd_smpl_store_pref', 'detail_lineno', 'seq');
ctx_ddl.set_attribute('xcd_smpl_store_pref', 'detail_text', 'txt_srch_xml');
END;
/

--Index Creation:
-----------------

CREATE INDEX xcd_sample_dmn1_idx 
ON xcd_sample_dmy_t(dummy) 
INDEXTYPE IS CTXSYS.CONTEXT PARAMETERS 
(' LEXER xcd_LEXER_pref WORDLIST xcd_word_pref datastore xcd_smpl_store_pref STOPLIST CTXSYS.EMPTY_STOPLIST') LOCAL;



CREATE INDEX xcd_tmp_dmn1_idx 
ON xcd_tmp_dmy_t(dummy) 
INDEXTYPE IS CTXSYS.CONTEXT PARAMETERS 
(' LEXER xcd_LEXER_pref WORDLIST xcd_word_pref datastore xcd_tmp_store_pref STOPLIST CTXSYS.EMPTY_STOPLIST');


--Drop Primary Key Constraints
------------------------------

set serverout on

DECLARE
  cname VARCHAR2(30);
  dsql  VARCHAR2(256);
BEGIN

  SELECT constraint_NAME INTO cname FROM user_constraints
  WHERE table_name = 'XCD_SAMPLE_DMY_T' AND constraint_type = 'P';
  dsql := 'ALTER TABLE xcd_sample_dmy_t DROP CONSTRAINT '||cname;
  DBMS_OUTPUT.PUT_LINE(dsql);
  EXECUTE IMMEDIATE (dsql);

  SELECT constraint_name INTO cname FROM user_constraints
  WHERE table_name = 'XCD_TMP_DMY_T' AND constraint_type = 'P';
  dsql := 'ALTER TABLE xcd_tmp_dmy_t DROP CONSTRAINT '||cname;
  DBMS_OUTPUT.PUT_LINE(dsql);
  EXECUTE IMMEDIATE (dsql);

end;
/



--Exchange Partition:
---------------------

ALTER TABLE xcd_sample_dmy_t ADD PARTITION PART_XCD_8 VALUES LESS THAN (9); 

ALTER TABLE xcd_sample_dmy_t 
EXCHANGE PARTITION PART_XCD_8 
WITH TABLE xcd_tmp_dmy_t 
INCLUDING INDEXES WITHOUT VALIDATION;


--Reinstate Primary Key on Main Table:
------------------------------------

ALTER TABLE xcd_sample_dmy_t ADD CONSTRAINT xcd_smp_dmy_pk_idx PRIMARY KEY (enty_id, enty_typ_mnm);
