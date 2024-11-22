drop table mytest;

exec ctx_ddl.drop_preference(('mylexer');
exec ctx_ddl.create_preference('mylexer', 'basic_lexer');
exec ctx_ddl.set_attribute('mylexer', 'index_themes', 'yes');
exec ctx_ddl.set_attribute('mylexer', 'prove_themes', 'no');

create table mytest(id number primary key, text varchar2(100));
insert into mytest values(1,'San Francisco');
insert into mytest values(2,'http://www.frobbleblot.com');
commit;

create index myindex on mytest(text) indextype is context
parameters ('lexer mylexer');

set serverout on

declare
  v_theme ctx_doc.theme_tab;
begin
  ctx_doc.themes (
    index_name=>'myindex',
    textkey=>'1',
    restab=>v_theme,
    full_themes=>true);

  for i in 1 .. v_theme.last loop
    dbms_output.put_line(v_theme(i).theme);
  end loop;

  ctx_doc.themes (
    index_name=>'myindex',
    textkey=>'2',
    restab=>v_theme,
    full_themes=>true);

  for i in 1 .. v_theme.last loop
    dbms_output.put_line(v_theme(i).theme);
  end loop;
end;
/
