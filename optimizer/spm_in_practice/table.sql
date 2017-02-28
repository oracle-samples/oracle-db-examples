DROP TABLE tab1 purge;

CREATE TABLE tab1 (id, txt) 
  AS SELECT level, CAST (to_char(level) AS varchar2(10)) FROM dual
  CONNECT BY level <= 10000
/

CREATE UNIQUE INDEX tabi ON tab1(id);

EXEC dbms_stats.gather_table_stats(USER, 'tab1');

