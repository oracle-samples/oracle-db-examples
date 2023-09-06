-- test table:
CREATE TABLE test_tab
  (col1	 VARCHAR2 (15),
	col2	 VARCHAR2 (15),
	all_cols VARCHAR2 ( 1))
/ 
-- test data:
INSERT ALL
 INTO test_tab (col1, col2) VALUES ('word1 word2', 'word3 word4')
 INTO test_tab (col1, col2) VALUES ('word2 word3', 'word4 word5')
 SELECT * FROM DUAL
/ 
-- multi_column_datastore:
BEGIN
  CTX_DDL.CREATE_PREFERENCE ('test_multi', 'MULTI_COLUMN_DATASTORE');
  CTX_DDL.SET_ATTRIBUTE ('test_multi', 'COLUMNS', 'col1, col2');
  CTX_DDL.SET_ATTRIBUTE ('test_multi', 'DELIMITER', 'NEWLINE');
END;
/ 
-- context index that uses multi_column_datastore:
CREATE INDEX test_idx ON test_tab (all_cols)
 INDEXTYPE IS CTXSYS.CONTEXT
 PARAMETERS ('DATASTORE test_multi')
/ 
 
-- select from domain index
-- with sum and group by in case index is fragmented:
SELECT token_text AS word,
 SUM (token_count) AS occurrences
 FROM   dr$test_idx$i
 GROUP  BY token_text
/ 
