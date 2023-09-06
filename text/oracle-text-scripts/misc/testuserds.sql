-- drop detail table first due to fk constraint

DROP TABLE DATASTORES_TAB_detail;
DROP TABLE DATASTORES_TAB;

CREATE TABLE DATASTORES_TAB
  (
    id        NUMBER PRIMARY KEY,
    author    VARCHAR2(80),
    document  VARCHAR2(3000),
    path      VARCHAR2(3000),
    path1     VARCHAR2(3000)
  );

INSERT INTO DATASTORES_TAB ( id, author, document,path,path1 ) VALUES
  ( 1,
    'John Grisham',
    'The user datastore is new for 8i.' ,'C:/oracle/oracle/path/text','C:/oracle/oracle/path1/text1');

INSERT INTO DATASTORES_TAB ( id, author, document,path,path1 ) VALUES
  ( 2,
    'Stephen King',
    'You write a stored procedure which, given a rowid, synthesizes a doc.',
    'C:/oracle/oracle/path/text2','C:/oracle/oracle/path1/text2' );

INSERT INTO DATASTORES_TAB ( id, author, document,path,path1 ) VALUES
  ( 3,
    'Joe Bloggs',
    EMPTY_CLOB() ,
    'C:/oracle/oracle/path/text3','C:/oracle/oracle/path1/text3');

INSERT INTO DATASTORES_TAB ( id, author, document,path,path1 ) VALUES
  ( 4,
    'Sid Smith',
    NULL,
    'G:/oracle/oracle/path/text4','G:/oracle/oracle/path1/text4' );

COMMIT;

CREATE TABLE  DATASTORES_TAB_detail
   (
    Detail_id   NUMBER PRIMARY KEY ,
    Detail_store_name VARCHAR2(2000),
    store_type        VARCHAR2(3000),
    id          NUMBER, FOREIGN KEY(id) REFERENCES DATASTORES_TAB (id)
   );  

INSERT INTO  DATASTORES_TAB_detail (DETAIL_ID, DETAIL_STORE_NAME, STORE_TYPE, ID)
                            VALUES (1,'Gathy','Mall',1) ; 
                            
INSERT INTO  DATASTORES_TAB_detail (DETAIL_ID, DETAIL_STORE_NAME, STORE_TYPE, ID)
                            VALUES (2,'Sathya','Mall',2) ;    
                            
INSERT INTO  DATASTORES_TAB_detail (DETAIL_ID, DETAIL_STORE_NAME, STORE_TYPE, ID)
                            VALUES (3,'Bala','Mall',3) ;
                            
INSERT INTO  DATASTORES_TAB_detail (DETAIL_ID, DETAIL_STORE_NAME, STORE_TYPE, ID)
                            VALUES (4,'Venkat','Mall',4) ;
  
-- this record gets rejected for foreign key violation                          
--INSERT INTO  DATASTORES_TAB_detail (DETAIL_ID, DETAIL_STORE_NAME, STORE_TYPE, ID)
--                            VALUES (5,'Meena','Mall',5) ;  

COMMIT;

--- to populate more records 

BEGIN
  
  FOR i IN 5..100000
  LOOP
  
  INSERT INTO DATASTORES_TAB ( id, author, document,path,path1 ) VALUES
  ( i,'Name  '||i,  'The user datastore is new for '||i || ' i.' ,NULL,'A:/sqlserver/text '||i );

  END LOOP;    
  COMMIT;
END;
/

BEGIN
    FOR i IN 6..10000
    LOOP   
         INSERT INTO  DATASTORES_TAB_detail (DETAIL_ID, DETAIL_STORE_NAME, STORE_TYPE, ID)
                      VALUES (i,'Name'||i,'STORE',i) ;
     END LOOP;
END;                           
/

-- create an index to make datastore procedure lookup more efficient

CREATE INDEX details_id_index ON datastores_tab_detail (id);

-- add dummy column and populate it

ALTER TABLE datastores_tab ADD dummy_col VARCHAR2(1);
UPDATE datastores_tab SET dummy_COL = 'X';

CREATE OR REPLACE PROCEDURE My_Proc_Test_detail( rid  IN     ROWID,
                                                 tlob IN OUT NOCOPY   CLOB    /* NOCOPY instructs Oracle to pass
                                                              this argument as fast as possible */ )
IS
   tempid number;
   tempvc varchar2(32767);
BEGIN

-- there should only be a single row in the master table corresponding to this rowid

SELECT id, author ||'   '|| document||'   '||path ||'   '||path1 ||'   ' INTO tempid, tempvc
FROM datastores_tab WHERE rowid = rid;

dbms_lob.append (tlob, tempvc);

-- but there could be multiple corresponding records in the detail table

FOR C IN (  SELECT DETAIL_STORE_NAME ||'   '|| STORE_TYPE|| '   ' stext
             FROM DATASTORES_TAB_DETAIL b
             WHERE b.ID = tempid )
LOOP
        dbms_lob.append (tlob, c.stext);

END LOOP;
END;
/
list 
show err

BEGIN
  ctx_ddl.drop_preference ( 'my_user_datastore' );
END;
/

BEGIN
  ctx_ddl.create_preference ( 'my_user_datastore', 'user_datastore' );
  ctx_ddl.set_attribute ( 'my_user_datastore', 'procedure','My_Proc_Test_detail' );
END;
/

CREATE INDEX datastores_concat ON DATASTORES_TAB ( dummy_col )
  indextype IS ctxsys.context
  parameters ( 'datastore my_user_datastore  SECTION GROUP CTXSYS.AUTO_SECTION_GROUP ' );


-- Now if iam executing the below query i will get one record in 13 seconds ,

set feedback 1

-- simple query

SELECT a.id, author
  FROM DATASTORES_TAB a
  WHERE contains ( dummy_col,'name 10000%' ) > 0; 

-- full join query for record with "name 10002" in it

SELECT a.id, author, document,path,path1 ,DETAIL_STORE_NAME, STORE_TYPE
  FROM DATASTORES_TAB a, DATASTORES_TAB_DETAIL b
  WHERE  a.ID = b.ID (+)
  AND contains ( dummy_col,'name 10002' ) > 0; 

