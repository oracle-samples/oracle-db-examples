-- a FORMAT column can be used to specify whether particular rows should
-- be indexed or ignored. It must have specific values TEXT, BINARY or IGNORE

-- but we can use a virtual column as a format column
-- lets say we only want PDF and DOCX files to be indexed, and we have the 
-- file type in a column, we can use a virtual column 'fmt' returning 
-- BINARY or IGNORE depending on the file type:

drop table t;

-- create a table with a generated column 'fmt' based on the value in doktypeid

create table t (
  c         varchar2(2000),
  doktypeid varchar2(10),
  fmt       varchar2(10) generated always as
              ( case when doktypeid in ('PDF','DOCX')
	             then 'BINARY'
	             else 'IGNORE' end ) );

-- insert some data

insert into t (c, doktypeid) values ('record1', 'PDF');
insert into t (c, doktypeid) values ('record2', 'DOCX');
insert into t (c, doktypeid) values ('record3', 'EXE');
insert into t (c, doktypeid) values ('record4', 'BIN');

-- create an index specifying virtual column fmt as the format column

create index i on t (c) indextype is ctxsys.context
parameters ('format column fmt')
/

-- check to see what's been indexed. We only expect to see record1 and record2 there

select token_text from dr$i$i;


