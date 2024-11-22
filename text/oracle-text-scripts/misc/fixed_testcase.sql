set define off

exec ctx_ddl.drop_stoplist  ('TEST_STOPLIST')
exec ctx_ddl.create_stoplist('TEST_STOPLIST', 'BASIC_STOPLIST'); 
exec ctx_ddl.add_stopclass  ('TEST_STOPLIST', 'LONGHEX', '[ABCDEF0123456789]{20,}'); 
exec ctx_ddl.add_stopclass  ('TEST_STOPLIST', 'MASS', 'M(A|E)SS'); 

exec ctx_ddl.drop_section_group  ('TEST_SG'); 
exec ctx_ddl.create_section_group('TEST_SG',  'XML_SECTION_GROUP'); 
exec ctx_ddl.add_zone_section    ('TEST_SG',  'TITLE', 'TITLE'); 
exec ctx_ddl.add_zone_section    ('TEST_SC,   'BODY', 'BODY');

drop table stoptest;

CREATE TABLE STOPTEST
(
"ID" VARCHAR2(10 BYTE) NOT NULL ENABLE,
"TEXTVAL" CLOB,
CONSTRAINT "STOPTEST_PK" PRIMARY KEY ("ID") );

INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0001', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: ABCDEF0123456789ABCDEF0123456789. Please help.</BODY></DOC>'); INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0002', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: 01CDEF0123456789ABCDEF0123456789. Please help.</BODY></DOC> 1 ); 
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0003', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: ABCCCC0123456789ABCDEF0123456789. Please help.</BODY></DOC> 1 );
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0004', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: 987DEF0123456789ABCDEF0123456789. Please help.</BODY></DOC> 1 );
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0005', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: FEDCBA0123456789ABCDEF0123456789. Please help.</BODY></DOC> 1 );
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0006', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: ABCDEF0123456789ABCDEF0123456789. Please help.</BODY></DOC> 1 );
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0007', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>O1CDEF0123456789ABCDEF0123456789. Please help.</BODY></DOC>');
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0008', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>ABCCCC0123456789ABCDEF0123456789</BODY></DOC> 1 );
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('A0009', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: 987DEF0123456789ABCDEF0123456789</BODY></DOC>');
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('AOOOA', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: FEDCBA0123456789ABCDEF0123456789. Please help.</BODY></DOC>');
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('AOOOB', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: FEDCBA012345G789ABCDEF0123456789. Please help.</BODY></DOC>');
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('AOOOC', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mess: HEDCBA012345G789ABCDEF0123456789. Please help.</BODY></DOC>');
INSERT INTO STOPTEST (ID, TEXTVAL) VALUES ('AOOOD', '<DOC> <TITLE>Broken Stopwords</TITLE><BODY>This is a mass: HEDCBA012345G789ABCDEF0123H56789. Please help.</BODY></DOC>');
COMMIT;

-- index 1 uses no section group

CREATE INDEX "STOPTEST_NDX" ON "STOPTEST" ("TEXTVAL") INDEXTYPE IS "CTXSYS"."CONTEXT" PARAMETERS ('STOPLIST TEST_STOPLIST');

drop table stoptest2;

-- table 2 is a direct copy of all rows in table 1

CREATE TABLE STOPTEST2
(
"ID" VARCHAR2(10 BYTE) NOT NULL ENABLE,
"TEXTVAL" CLOB,
CONSTRAINT "STOPTEST2_PK" PRIMARY KEY ("ID") );

INSERT INTO STOPTEST2 (ID, TEXTVAL) SELECT ID, TEXTVAL FROM STOPTEST;
COMMIT;

-- index 2 uses XML section group

CREATE INDEX "STOPTEST2_NDX" ON "STOPTEST2" ("TEXTVAL") INDEXTYPE IS "CTXSYS"."CONTEXT" PARAMETERS ('STOPLIST TEST_STOPLIST SECTION GROUP TEST_SG');


select token_text "All tokens no section group" from DR$STOPTEST_NDX$I order by token_text;

select token_text "All token XML_SECTION_GROUP" from DR$STOPTEST2_NDX$I order by token_text;

-- find differences 

select t1.token_text "Extra tokens no section group"
  from DR$STOPTEST_NDX$I t1 where t1.token_text not in
  (select t2.token_text from DR$STOPTEST2_NDX$I t2 )
  order by t1.token_text;

select t2.token_text "Extra tokens XML_SECTION_GROUP" 
  from DR$STOPTEST2_NDX$I t2 where t2.token_text not in
  (select t1.token_text from DR$STOPTEST_NDX$I t1 )
  order by t2.token_text;
