select * from x where contains(text, 'fox') > 0;

drop table t;

create table t (
  c         varchar2(2000),
  doktypeid varchar2(10),
  fmt       varchar2(10) generated always as
        ( case when doktypeid in ('PDF','DOCX')
	       then 'BINARY'
	       else 'IGNORE' end )
	       );

insert into t (c, doktypeid) values ('record1', 'PDF');
insert into t (c, doktypeid) values ('record2', 'DOCX');
insert into t (c, doktypeid) values ('record3', 'EXE');
insert into t (c, doktypeid) values ('record4', 'BIN');

create index i on t (c) indextype is ctxsys.context
parameters ('format column fmt')
/

select token_text from dr$i$i;


