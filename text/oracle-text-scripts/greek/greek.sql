-- before starting SQL*Plus to run this script run

--- export NLS_LANG=greek_greece.al32utf8

-- also run this as SYS to enable AUTO_LEXER unless you have the patch installed:
-- alter system set events '30579 trace name context forever, level 67108864';

set echo on

--Source table
--This script creates a table that stores the data indexed
drop table srch;

CREATE TABLE SRCH
(
  LIL_ID           NUMBER(10),
  L_ID             NUMBER(4),
  LANG_CODE        VARCHAR2(5 BYTE),
  TL_ID            NUMBER(10),
  INTERMEDIA_CODE  VARCHAR2(40 BYTE)            DEFAULT 'ENGLISH',
  CONFID           VARCHAR2(1 BYTE),
  PRIM_ENT         INTEGER                      DEFAULT 0,
  SEARCH           CLOB,
  LEN_TERM         NUMBER(5),
  SEARCH_NSW       CLOB
)
/

--Stems not working examples
--Texts stored in SEARCH column, for all other columns can use dummy data
--Greek example L_ID = 5:

-- house / home 
insert into srch (lil_id, intermedia_code, search) values (1, 'greek', 'σπίτια'); 
insert into srch (lil_id, intermedia_code, search) values (2, 'greek', 'Σπίτι');
-- running
insert into srch (lil_id, intermedia_code, search) values (3, 'greek', 'Τρέχει'); 
-- ran
insert into srch (lil_id, intermedia_code, search) values (4, '$Έτρεξε');
-- antelope
insert into srch (lil_id, intermedia_code, search) values (5, 'greek', 'αντιλόπη');
-- antelopes
insert into srch (lil_id, intermedia_code, search) values (6, 'greek', 'Αντιλόπες');
-- unemployment
insert into srch (lil_id, intermedia_code, search) values (7, 'greek', 'ανεργία');
insert into srch (lil_id, intermedia_code, search) values (8, 'greek', 'ανεργίας');


--“Σπίτι” should find also “σπίτια” and vice versa
--“κινητή αξία” should find also “κινητές αξίες” and vice versa
--“ανεργία” should find also “ανεργίας” and vice versa
--“εργασία” should find also “εργασίας” and vice versa
--“αναφορά” should find also “αναφοράς” and vice versa
--Index creation

exec ctx_ddl.drop_preference('SRCH_TXT_IDX_LEX')

begin
  ctx_ddl.create_preference('SRCH_TXT_IDX_LEX','MULTI_LEXER');
end;
/

exec ctx_ddl.drop_preference('SRCH_TXT_IDX_L00')

begin
  ctx_ddl.create_preference('SRCH_TXT_IDX_L00','BASIC_LEXER');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_L00','PRINTJOINS','@$%');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_L00','BASE_LETTER','YES');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_L00','WHITESPACE','~!#^&*()_+|\=<>?{}[]-/:.,''');
end;
/

exec ctx_ddl.drop_preference('SRCH_TXT_IDX_LGB')

begin
  ctx_ddl.create_preference('SRCH_TXT_IDX_LGB','BASIC_LEXER');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LGB','PRINTJOINS','@$%');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LGB','BASE_LETTER','YES');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LGB','WHITESPACE','~!#^&*()_+|\=<>?{}[]-/:.,''');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LGB','INDEX_STEMS','ENGLISH');
end;
/

exec ctx_ddl.drop_preference('SRCH_TXT_IDX_LF')

begin
  ctx_ddl.create_preference('SRCH_TXT_IDX_LF','BASIC_LEXER');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LF','PRINTJOINS','@$%');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LF','BASE_LETTER','YES');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LF','WHITESPACE','~!#^&*()_+|\=<>?{}[]-/:.,''');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LF','INDEX_STEMS','FRENCH');
end;
/

exec ctx_ddl.drop_preference('SRCH_TXT_IDX_LEL')

begin
  ctx_ddl.create_preference('SRCH_TXT_IDX_LEL','BASIC_LEXER');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LEL','PRINTJOINS','@$%]');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LEL','BASE_LETTER','YES');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LEL','WHITESPACE','~!#^&*()_+|\=<>?{}[]-/:.,''');
  ctx_ddl.set_attribute('SRCH_TXT_IDX_LEL ','INDEX_STEMS', 'GREEK');

end;
/

begin
  ctx_ddl.add_sub_lexer('SRCH_TXT_IDX_LEX','DEFAULT','SRCH_TXT_IDX_L00');
  ctx_ddl.add_sub_lexer('SRCH_TXT_IDX_LEX','ENGLISH','SRCH_TXT_IDX_LGB');
  ctx_ddl.add_sub_lexer('SRCH_TXT_IDX_LEX','FRENCH','SRCH_TXT_IDX_LF');
  ctx_ddl.add_sub_lexer('SRCH_TXT_IDX_LEX','GREEK','SRCH_TXT_IDX_LEL');
end;
/

exec ctx_ddl.drop_preference('SRCH_TXT_IDX_WDL')

begin
  ctx_ddl.create_preference('SRCH_TXT_IDX_WDL','BASIC_WORDLIST');
  -- uncomment this next line and the searches will not work
  -- ctx_ddl.set_attribute('SRCH_TXT_IDX_WDL','STEMMER','AUTO');
end;
/

create index SRCH_TXT_IDX 
  on SRCH
      (SEARCH)
  indextype is ctxsys.context
  parameters('
    lexer           SRCH_TXT_IDX_LEL
    wordlist        SRCH_TXT_IDX_WDL
    language column INTERMEDIA_CODE
    sync (on commit)
  ')
/

select token_type, token_text from dr$srch_txt_idx$i;

-- Sample query for stemming:
-- Before the query is executed there is a step that changes NLS_LANGUAGE database parameter.
alter session set NLS_LANGUAGE = 'GREEK';

column search format a20

SELECT lil_id, search FROM srch WHERE contains (search, '$σπίτια') > 0;

SELECT lil_id, search FROM srch WHERE contains (search, '$Σπίτι') > 0;

SELECT lil_id, search FROM srch WHERE contains (search, '$Έτρεξε') > 0;

SELECT lil_id, search FROM srch WHERE contains (search, '$Τρέχει') > 0;

SELECT lil_id, search FROM srch WHERE contains (search, '$Αντιλόπες') > 0;

SELECT lil_id, search FROM srch WHERE contains (search, '$αντιλόπη') > 0;

SELECT lil_id, search FROM srch WHERE contains (search, '$ανεργία') > 0;

SELECT lil_id, search FROM srch WHERE contains (search, '$ανεργίας') > 0;

