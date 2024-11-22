set serverout on
drop table msg_log_32;
create table msg_log_32 (pk number primary key, msgtarget varchar2(20),
msgdata varchar2(2000));
insert into msg_log_32 values (1, 'test', '<msgTarget>abc</msgTarget>');
commit;
create index mymsgindex on msg_log_32 (msgdata) indextype is ctxsys.context
parameters('section group ctxsys.auto_section_group');

declare
  string_search varchar2(4000);
  target varchar2(20) default 'abc';
  var_msgtarget varchar2(100);
  sample varchar2(2000);
begin
  string_search := target||' within msgTarget';
  dbms_output.put_line('string_search = '||string_search);
  SELECT /*+ FIRST_ROWS INDEX(msg_log_32 msg_log_32_msgdata) */
    msgtarget into var_msgtarget FROM msg_log_32 
    WHERE contains (msgdata, string_search)>0;
  dbms_output.put_line(var_msgtarget);
end;
/