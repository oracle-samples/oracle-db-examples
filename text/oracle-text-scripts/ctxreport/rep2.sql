drop table mytable;

create table mytable (text varchar2(2000));

insert into mytable values ('the quick brown fox');

exec ctx_ddl.drop_preference('MYWORD')

begin
  ctx_ddl.create_preference('MYWORD','BASIC_WORDLIST');
  ctx_ddl.set_attribute('MYWORD','STEMMER','NULL');
  ctx_ddl.set_attribute('MYWORD','WILDCARD_MAXTERMS','50000');
  ctx_ddl.set_attribute('MYWORD','PREFIX_INDEX','YES');
  ctx_ddl.set_attribute('MYWORD','PREFIX_MAX_LENGTH','4');
end;
/

create index myindex on mytable(text)
indextype is ctxsys.context
parameters ('wordlist myword')
/

REM   script to get info about an Oracle Text index
REM   change the name of the index in the DEFINE below
REM   do not add quotes or a semicolon at the end
REM   the third part of this script (ctx_report.index_stats)
REM   may take several hours to run

define index_name = MYINDEX

set head off
set pagesize 0
set linesize 130
set long 500000
set trimspool on

variable myclob clob

begin
   dbms_lob.createtemporary(:myclob, true);
   ctx_report.create_index_script('&index_name.', :myclob);
end;
/

spool index_script.log
print myclob
spool off

begin
   dbms_lob.createtemporary(:myclob, true);
   ctx_report.index_size('&index_name.', :myclob);
end;
/

spool index_size.log
print myclob
spool off

begin
   dbms_lob.createtemporary(:myclob, true);
   ctx_report.index_stats('&index_name.', :myclob);
end;
/

spool index_stats.log
print myclob
spool off

quit

