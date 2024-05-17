exec ctx_ddl.drop_section_group('mysec')
exec ctx_ddl.create_section_group('mysec', 'BASIC_SECTION_GROUP')

begin
  for i in 1 .. 1000 loop
     execute immediate ('begin ctx_ddl.add_field_section(''mysec'', ''field' || i || ''', ''field' || i || '''); end;');
  end loop;
end;
/

drop table t;

create table t (c varchar2(2000));
begin
   for i in  1 .. 1000 loop
      for j in 1 .. 1 loop
         insert into t values ('xyz <field' || i || '>hello</field' || i ||'> abc');
      end loop;
   end loop;
end;
/

create index ti on t(c) indextype is ctxsys.context parameters ('section group mysec sync(on commit)');

select count(*) from t where contains (c, 'hello within field777') > 0;

exec ctx_ddl.add_field_section('mysec', 'field1001', 'field1001')

-- alter index ti rebuild parameters ('replace metadata section group mysec');
alter index ti rebuild parameters ('add field section field1001 tag field1001');

insert into t values ('<field1001>foo</field1001>');
commit;

select count(*) from t where contains (c, 'foo within field1001') > 0;
