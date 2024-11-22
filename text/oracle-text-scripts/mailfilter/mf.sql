drop table mail;

create table mail (id number primary key,doc varchar2(80));
insert into mail values(1,'e:\mail\message.eml');
insert into mail values(2,'e:\mail\message2.eml');
commit;

begin
  ctx_ddl.drop_preference ('my_mail_filter');
  end;
/

begin
  ctx_ddl.drop_section_group ('my_section_group');
  end;
/

begin
  ctx_ddl.drop_stoplist ('my_stoplist');
  end;
/

begin
  ctx_ddl.create_preference('my_mail_filter','mail_filter');
  ctx_ddl.set_attribute('my_mail_filter','index_fields','To : TO');
  ctx_ddl.set_attribute('my_mail_filter','inso_timeout','60');
  ctx_ddl.set_attribute('my_mail_filter','inso_output_formatting','TRUE');
 end;
/

begin
  ctx_ddl.create_section_group('my_section_group', 'basic_section_group');
  ctx_ddl.add_field_section('my_section_group', 'to', 'to');
end;
/

begin
  ctx_ddl.create_stoplist('my_stoplist', 'BASIC_STOPLIST');
  ctx_ddl.add_stopclass('my_stoplist','NUMBERS');
end;
/

create index mail_index on mail(doc) indextype is ctxsys.context
  parameters('datastore ctxsys.file_datastore filter my_mail_filter section group my_section_group');

select token_text,token_type from dr$mail_index$i order by 2,1;
