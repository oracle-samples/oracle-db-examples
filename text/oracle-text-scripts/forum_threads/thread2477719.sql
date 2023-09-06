DROP TABLE my_table
/
CREATE TABLE my_table (column1  VARCHAR2(60))
/ 
INSERT ALL
 INTO my_table VALUES ('test')
 INTO my_table VALUES ('testing')
 INTO my_table VALUES ('my-test')
 INTO my_table VALUES ('owr-test')
 SELECT * FROM DUAL
/ 

exec ctx_ddl.drop_preference('SUBSTRING_PREF')
exec ctx_ddl.drop_preference('mcds')

BEGIN
   ctx_ddl.create_preference('SUBSTRING_PREF','BASIC_WORDLIST');
   ctx_ddl.set_attribute('SUBSTRING_PREF','SUBSTRING_INDEX','TRUE');
   CTX_DDL.CREATE_PREFERENCE ('test_lex', 'BASIC_LEXER');
   CTX_DDL.SET_ATTRIBUTE ('test_lex', 'PRINTJOINS', '-');
END;
/ 

BEGIN
  ctx_ddl.create_preference('mcds', 'MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('mcds', 'COLUMNS', '''XZX''||COLUMN1');
END;
/

CREATE INDEX IDX_TEXT_1 ON MY_TABLE (COLUMN1)
 INDEXTYPE IS CTXSYS.CONTEXT
 PARAMETERS
   ('wordlist  SUBSTRING_PREF
 	 LEXER	   test_lex
         DATASTORE mcds
	 memory    50m')
 NOPARALLEL
/ 
 
SELECT token_text FROM dr$idx_text_1$i
/ 
SELECT mt.*
  FROM   MY_TABLE mt
  WHERE  contains (mt.COLUMN1, 'XZXtest%') > 0
/ 
