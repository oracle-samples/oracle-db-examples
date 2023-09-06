drop table test_tbl;

CREATE TABLE test_tbl
  (id NUMBER, text VARCHAR2(4000), par_id NUMBER);
-- Create Table, Load Data and Inxex
INSERT INTO test_tbl VALUES
  ( 1, 'the little dog played with the big dog
     while the other dog ate the dog food', 2);
INSERT INTO test_tbl values
  (2, 'the cat played with the dog', null);

CREATE INDEX
  test_tbl_idx ON test_tbl (text)
  indextype is ctxsys.context;

-- SQL with Score that works..
SELECT SCORE(10) FROM test_tbl WHERE CONTAINS (text, 'dog ACCUM cat', 10) > 0;

-- SQL where SCORE does not work...
SELECT SCORE(10) FROM test_tbl 
      start with CONTAINS (text, 'dog ACCUM cat') > 0 
      CONNECT BY NOCYCLE PRIOR par_id = id
      AND CONTAINS (text, 'dog ACCUM cat', 10) >= 0;

-- without the score
SELECT * FROM test_tbl 
      start with CONTAINS (text, 'dog ACCUM cat') > 0 
      CONNECT BY NOCYCLE PRIOR par_id = id;

column id format 999
column par_id format 999
column text format a60
set linesize 150

-- Non-text SQL for comparison
SELECT * FROM test_tbl 
      start with text LIKE '%little%dog%'
      CONNECT BY NOCYCLE PRIOR par_id = id;

SELECT score(10) FROM test_tbl 
      WHERE CONTAINS (text, 'food') > 0
      start with CONTAINS (text, 'food') > 0 
      CONNECT BY NOCYCLE PRIOR par_id = id
      AND CONTAINS (text, 'food', 10) >= 0;

set serverout on

begin
   for c1 in 
     ( select id, text, par_id, score(1) as scr from test_tbl where contains( text, 'food', 1) > 0 ) loop
      dbms_output.put_line( 'Child  - Score: ' || c1.scr || ' Id = '|| c1.id || ' Text: ' || c1.text || ' Par_id: ' || c1.par_id );
      for c2 in ( select id, text, par_id from test_tbl where id = c1.par_id ) loop
         dbms_output.put_line( 'Parent - Score: ' || c1.scr || ' Id = '|| c2.id || ' Text: ' || c2.text || ' Par_id: ' || c2.par_id );
      end loop;
   end loop;
end;
/
 
