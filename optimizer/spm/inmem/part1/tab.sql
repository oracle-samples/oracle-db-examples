DROP table mysales;

CREATE TABLE mysales (
 id  NUMBER(10)
,val VARCHAR2(100));

INSERT INTO mysales
SELECT ROWNUM,'X'
FROM   ( SELECT 1
         FROM   dual
         CONNECT BY LEVEL <= 100000
       );

COMMIT;

EXECUTE dbms_stats.gather_table_stats(ownname=>NULL,tabname=>'MYSALES');
