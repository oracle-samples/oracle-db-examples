DROP TABLE TEMP_FUZZY;

CREATE TABLE TEMP_FUZZY
(
  TEXTCOL  VARCHAR2(2000 BYTE),
  DATECOL  VARCHAR2(2000 BYTE)
);
 
INSERT ALL
 INTO TEMP_FUZZY VALUES ('myt', '1958')
 INTO TEMP_FUZZY VALUES ('myt', '2009')
 INTO TEMP_FUZZY VALUES ('mytex', '1958')
 INTO TEMP_FUZZY VALUES ('mytex', '2009')
 INTO TEMP_FUZZY VALUES ('mytext', '1958')
 INTO TEMP_FUZZY VALUES ('mytext', '2009')
 INTO TEMP_FUZZY VALUES ('mytext-is', '1958')
 INTO TEMP_FUZZY VALUES ('mytext-is', '2009')
 INTO TEMP_FUZZY VALUES ('mytext-is-long', '1958')
 INTO TEMP_FUZZY VALUES ('mytext-is-long', '2009')
 INTO TEMP_FUZZY VALUES ('mytext-is-longer', '1958')
 INTO TEMP_FUZZY VALUES ('mytext-is-longer', '2009')
SELECT * FROM DUAL;
 
COMMIT;

exec ctx_ddl.drop_preference('temp_fuzzy_pref');
 
DECLARE
  v_column VARCHAR2(2000);
BEGIN
  v_column := 'textcol, datecol';
  CTX_DDL.CREATE_PREFERENCE ('temp_fuzzy_pref', 'MULTI_COLUMN_DATASTORE');
  CTX_DDL.SET_ATTRIBUTE     ('temp_fuzzy_pref', 'COLUMNS', v_column );
END;
/ 
 
CREATE INDEX idx_temp_fuzzy ON temp_fuzzy (textcol)
 INDEXTYPE IS CTXSYS.CONTEXT
 PARAMETERS ('DATASTORE temp_fuzzy_pref SECTION GROUP CTXSYS.AUTO_SECTION_GROUP STOPLIST CTXSYS.EMPTY_STOPLIST');
 
COLUMN textcol FORMAT a10
COLUMN datecol FORMAT a20
 
VARIABLE bnd VARCHAR2(200)
 
EXEC :bnd := '?mytext% WITHIN textcol AND ?1% WITHIN datecol';
 
SELECT SCORE(0), textcol, datecol 
  FROM temp_fuzzy
 WHERE CONTAINS(textcol, :bnd, 0 ) > 0;

EXEC :bnd := 'mytext WITHIN textcol AND ?1% WITHIN datecol';
 
SELECT SCORE(0), textcol, datecol 
  FROM temp_fuzzy
 WHERE CONTAINS(textcol, :bnd, 0 ) > 0;

EXEC :bnd :=  'FUZZY(mytext%, 60, 500, N) WITHIN textcol AND FUZZY(1%, 60, 100, N) WITHIN datecol';

SELECT SCORE(0), textcol, datecol 
  FROM temp_fuzzy
 WHERE CONTAINS(textcol, :bnd, 0 ) > 0;
