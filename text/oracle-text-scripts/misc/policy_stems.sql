drop table foo;

create table foo (id number primary key, bar varchar2(2000));

insert into foo values (1, 'The quicker brown foxes are jumping over the lazier dogs');

create index fooindex on foo(bar) indextype is ctxsys.context;

exec ctx_ddl.drop_preference('mylex')
exec ctx_ddl.drop_policy( 'MYPOL')

exec ctx_ddl.create_preference('mylex', 'AUTO_LEXER')
exec ctx_ddl.create_policy( POLICY_NAME => 'MYPOL', LEXER => 'MYLEX' )

set serverout on

declare 
   stemgroup ctx_doc.stem_group_tab;
   stemtab   ctx_doc.stem_tab;
   stemrec   ctx_doc.stem_rec;
   text clob;
begin
   select bar into text from foo where id = 1;
   ctx_doc.policy_stems('mypol', text, stemgroup);
   for i in 1 .. stemgroup.last loop
     dbms_output.put_line('word '||stemgroup(i).word);
     stemtab := stemgroup(i).stems;
     for k in 1 .. stemtab.last loop
        if stemtab(k).is_in_lexicon then
          dbms_output.put_line('.  stem '||stemtab(k).stem ||' in lexicon: true');
        else
          dbms_output.put_line('.  stem '||stemtab(k).stem ||' in lexicon: false');
        end if;
     end loop;
   end loop;
end;
/
