set echo on

drop index lib_index;
drop table test_table;
exec ctx_ddl.drop_section_group('mysg');

create table test_table 
  (id number primary key, 
   month_info clob);

insert into test_table values (1, '<month>022003</month>');
insert into test_table values (2, '<month>082003</month>');
insert into test_table values (3, '<month>072003</month>');
insert into test_table values (4, '<month>012003</month>');
insert into test_table values (5, '<month>122003</month>');
insert into test_table values (6, '<month>122003</month>');
insert into test_table values (7, '<month>082003</month>');
insert into test_table values (8, '<month>032003</month>');
insert into test_table values (9, '<month>022003</month>');
insert into test_table values (10, '<month>092003</month>');
insert into test_table values (11, '<month>102003</month>');
insert into test_table values (12, '<month>112003</month>');
insert into test_table values (13, '<month>032003</month>');
insert into test_table values (14, '<month>032003</month>');
insert into test_table values (15, '<month>012003</month>');
insert into test_table values (16, '<month>092003</month>');

exec ctx_ddl.create_section_group(group_name=>'mysg', group_type=>'xml_section_group');

exec ctx_ddl.add_mdata_section(group_name=>'mysg', section_name=>'month', tag=>'month');

create index lib_index on test_table (book_info)
indextype is ctxsys.context 
parameters ('section group mysg');

select err_text from ctx_user_index_errors where err_index_name = 'LIB_INDEX';

column book_info format a30

select score(1), book_info from test_table 
where contains (month_info, '
<query>
  <textquery>
    <progression>
      <seq> mdata(month, 122003) </seq>
      <seq> mdata(month, 112003) </seq>
      <seq> mdata(month, 102003) </seq>
      <seq> mdata(month, 092003) </seq>
      <seq> mdata(month, 082003) </seq>
      <seq> mdata(month, 072003) </seq>
      <seq> mdata(month, 062003) </seq>
      <seq> mdata(month, 052003) </seq>
      <seq> mdata(month, 042003) </seq>
      <seq> mdata(month, 032003) </seq>
      <seq> mdata(month, 022003) </seq>
      <seq> mdata(month, 012003) </seq>
   </progression>
 </textquery>
</query>
',1) > 0 and rownum <= 5;
