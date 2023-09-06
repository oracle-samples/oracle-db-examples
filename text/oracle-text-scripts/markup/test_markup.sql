conn / as sysdba



show user
PROMPT SQL> DROP USER TEST_MARKUP

drop user TEST_MARKUP cascade;
prompt -- drop tablespace
drop tablespace TESTMARKUP including contents and datafiles;
create tablespace TESTMARKUP datafile 'markup.dbf' size 10M autoextend on next 10M;
prompt SQL>create directory
create or replace directory DOCUMENT_DIR as '&directory';

prompt SQL> CREATE USER
create user TEST_MARKUP identified by oracle account unlock default tablespace TESTMARKUP;
grant connect, resource, dba,ctxapp, create any table to TEST_MARKUP;
grant read, write on directory DOCUMENT_DIR to TEST_MARKUP;

conn TEST_MARKUP/oracle
show user

PROMPT CREATE PREFERENCES
begin
  CTX_DDL.Create_Preference('TEST_STORAGE', 'BASIC_STORAGE');

  /*  I_TABLE is the Token Table, main table of Text index   */
  CTX_DDL.set_attribute('TEST_STORAGE','I_TABLE_CLAUSE',
  'tablespace USERS storage (initial 100M next 10M)');

  /*  K_TABLE is the Mapping Table  */
  CTX_DDL.set_attribute('TEST_STORAGE', 'K_TABLE_CLAUSE',
  'tablespace USERS storage (initial 100M next 10M)');

  /* R_TABLE is the Denormalized Mapping Table (the "rowid row")
  Note: It is very important to add 'lob (data) store as (cache)' clause */
  CTX_DDL.set_attribute('TEST_STORAGE', 'R_TABLE_CLAUSE',
  'tablespace USERS storage (initial 10M) lob (data) store as (cache)');

  /* N_TABLE is the Negative List Table, it has rows only when deletes (or updates)
      have been done since the Text index was last sync'd */
  CTX_DDL.set_attribute('TEST_STORAGE', 'N_TABLE_CLAUSE',
  'tablespace USERS storage (initial 10M)');

  /* I_INDEX is the index on the I_TABLE  Token Table
      Note: It is very important not to skip 'compress 2' clause */
  CTX_DDL.set_attribute('TEST_STORAGE', 'I_INDEX_CLAUSE',
  'tablespace USERS storage (initial 30M) compress 2');

  /* P_TABLE is the Pattern Table, it exists when SUBSTRING_INDEX is TRUE
      and accelerates %ation queries  */
  CTX_DDL.set_attribute('TEST_STORAGE', 'P_TABLE_CLAUSE',
  'tablespace USERS storage (initial 1M)');
end;
/

PROMPT
PROMPT  Creating lexer preference...

begin
  CTX_DDL.create_preference('TEST_LEXER','BASIC_LEXER');
  CTX_DDL.set_attribute('TEST_LEXER','index_themes','NO');
  CTX_DDL.set_attribute('TEST_LEXER', 'PRINTJOINS', '.-');
end;
/

PROMPT
PROMPT  Creating wordlist preference...

begin
  CTX_DDL.create_preference('TEST_WORDLIST','BASIC_WORDLIST');
  CTX_DDL.set_attribute('TEST_WORDLIST','STEMMER', 'ITALIAN');
  CTX_DDL.set_attribute('TEST_WORDLIST','FUZZY_MATCH', 'ITALIAN');
end;
/

PROMPT
PROMPT  Creating filter preference...
begin
  CTX_DDL.create_preference ('TEST_FILTER','AUTO_FILTER');
  CTX_DDL.set_attribute('TEST_FILTER', 'TIMEOUT', '900');
end;
/


PROMPT
PROMPT  Creating stoplist (commentata 'sara')...

begin
  ctx_ddl.create_stoplist('TEST_STOPLIST');

  ctx_ddl.add_stopword('TEST_STOPLIST', 'adesso');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'a');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ad');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ai');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'al');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'alcuna');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'alcune');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'alcuni');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'all');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'alla');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'alle');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'allora');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'altresi');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'altro');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'altri');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'altrimenti');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'anche');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'anzi');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'atto');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'avendo');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'aveva');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'aver');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'avere');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'avuto');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ben');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'che');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'chi');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ci');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'cio');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'cioe');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'cioè');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'come');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'con');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'cui');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'D');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'DR');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'da');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dagli');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dal');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dall');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dalla');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dalle');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'del');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dell');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'della');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'delle');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dello');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'degli');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dei');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'deve');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'detto');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'di');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'disse');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'dopo');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'due');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'e');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ed');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'egli');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'era');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'erano');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ero');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'essere');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'fà');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'fa');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'fare');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'fatto');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'fra');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'fu');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'gia');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'gli');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ha');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ho');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'i');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'il');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'in');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'invece');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'io');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'l');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'la');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'le');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'lo');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'lui');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ma');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'mia');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'mio');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'mi');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'modo');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'n');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ne');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'necessità');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'no');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'noi');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'non');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'nella');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'nel');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'nr');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'o');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'oppure');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ora');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'ore');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'per');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'perche');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'perché');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'però');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'più');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'piu');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'possono');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'poiché');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'presso');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'prima');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'proprio');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'può');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'puo');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quale');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quali');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'qualche');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'qualunque');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quando');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quanti');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quanto');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quel');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quella');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quelle');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quelli');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quello');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'questo');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'questa');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'queste');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'questi');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'quindi');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'R');
  --ctx_ddl.add_stopword('TEST_STOPLIST', 'sara');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'se');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'si');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sia');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'solo');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'soltanto');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sono');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'stato');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'stata');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'su');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sua');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sue');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sui');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sul');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sull');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sulla');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'sulle');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'suo');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'tanto');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'tra');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'un');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'una');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'uno');
  ctx_ddl.add_stopword('TEST_STOPLIST', 'vi');
end;
/


PROMPT Create table for test....


CREATE TABLE TEST_DOC
(
  DOC_ID   NUMBER NOT NULL PRIMARY KEY,
  DOC_NAME VARCHAR2(255),
  DOC_FILE BLOB DEFAULT empty_blob()
);

CREATE TABLE TEST_RESULT
(
  PROG NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY (START WITH 1 NOCACHE),
  RESULT   CLOB
);


PROMPT SQL> INSERT INTO TEST_DOC

PROMPT SQL> CREATE SEQUENCE

CREATE SEQUENCE document_seq
INCREMENT BY 1
START WITH 1
NOMAXVALUE
NOCYCLE;

PROMPT SQL> CREATE FUNCTION TO INSERT data ( CREATE PROCEDURE INSERTBLOBFILE)

CREATE OR REPLACE PROCEDURE insertBLOBFile
(
    dir   VARCHAR2,
    file  VARCHAR2,
    name  VARCHAR2 := NULL
)
IS
 theBFile    BFILE;
  theBLob     BLOB;
   theDocName  VARCHAR2(200) := NVL(name, file);

BEGIN
      -- (1) Insert a new row into document_BLOB_tab with an empty BLOB, and
      -- (2) Retrieve the empty BLOB into a variable with RETURNING ... INTO
      INSERT INTO TEST_DOC (doc_id, doc_name, DOC_FILE)
        VALUES (document_seq.nextval, theDocName, empty_blob())
        RETURNING DOC_FILE INTO theBLob;

      DBMS_OUTPUT.PUT_LINE('SETTING: theDocName: ' || theDocName);
      DBMS_OUTPUT.PUT_LINE('SETTING: dir: ' || dir);
      DBMS_OUTPUT.PUT_LINE('SETTING: file: ' || file);

      -- (3) Get a BFile handle to the external file
      theBFile := BFileName(dir, file);

         -- (4) Open the file
 DBMS_LOB.fileOpen(theBFile);

 -- (5) Copy the contents of the BFile into the empty BLOB
         DBMS_LOB.loadFromFile(  dest_lob => theBLob
                       , src_lob  => theBFile
                              , amount   => DBMS_LOB.getLength(theBFile));

      -- (6) Close the file and commit
      DBMS_LOB.fileClose(theBFile);

     COMMIT;
  END;
  /

PROMPT SQL> INSERT DATA ITSELF

EXEC insertBLOBFile('DOCUMENT_DIR', 'esempio.docx');

commit;

select table_name from user_tables;

drop index IDX_INTR;


PROMPT SQL> CREATE TEXT index

CREATE INDEX IDX_INTR ON TEST_DOC
(DOC_FILE)
INDEXTYPE IS CTXSYS.CONTEXT
PARAMETERS('FILTER TEST_MARKUP.TEST_FILTER
            LEXER TEST_MARKUP.TEST_LEXER
           WORDLIST TEST_MARKUP.TEST_WORDLIST
             STOPLIST TEST_MARKUP.TEST_STOPLIST
           STORAGE TEST_MARKUP.TEST_STORAGE
            MEMORY 52428800')
PARALLEL ( DEGREE 8 INSTANCES 1 );

PROMPT SQL> CREATE PROCEDURE 1

DECLARE
   r_Row ROWID;
   TXTCONDITION VARCHAR2(4000);
   c_Documento CLOB;
 BEGIN
     SELECT ROWID INTO r_Row FROM TEST_DOC WHERE DOC_ID=1;
     TXTCONDITION := 'NEAR((POMIGLIANO,D''ARCO),0)';
     CTX_DOC.SET_KEY_TYPE('ROWID');
     CTX_DOC.MARKUP(index_name => 'IDX_INTR',
         textkey    => r_ROW,
         text_query => TXTCONDITION,
         restab     => c_Documento,
    plaintext  => TRUE,
    tagset     => 'TEXT_DEFAULT',
         starttag   => '<<',
         endtag     => '>>');
     INSERT INTO TEST_RESULT(RESULT) VALUES(c_Documento);
     COMMIT;
 END;
/

PROMPT SQL> CREATE PROCEDURE 2

DECLARE
   r_Row ROWID;
   TXTCONDITION VARCHAR2(4000);
   c_Documento CLOB;
 BEGIN
     SELECT ROWID INTO r_Row FROM TEST_DOC WHERE DOC_ID=1;
     TXTCONDITION := 'NEAR((POMIGLIANO,D''ARCO),1)';
     CTX_DOC.SET_KEY_TYPE('ROWID');
     CTX_DOC.MARKUP(index_name => 'IDX_INTR',
         textkey    => r_ROW,
         text_query => TXTCONDITION,
         restab     => c_Documento,
    plaintext  => TRUE,
    tagset     => 'TEXT_DEFAULT',
         starttag   => '<<',
         endtag     => '>>');
     INSERT INTO TEST_RESULT(RESULT) VALUES(c_Documento);
     COMMIT;
 END;
/

PROMPT SQL> SELECT FROM TEST_RESULT
select * from TEST_RESULT;
