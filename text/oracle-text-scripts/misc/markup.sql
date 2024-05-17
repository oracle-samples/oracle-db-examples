drop table test1;
create table test1 (id number primary key, text varchar2(80));

insert into test1 values (1, 'the quick brown fox jumps over the lazy dog');
insert into test1 values (2, 'the quick brown foxes jump over the lazy dog');
insert into test1 values (3, 'the quick brown fox jumped over the lazy dog');
insert into test1 values (4, 'jump jumping jumper jumped jumpology jumpee');

create index test1_index on test1(text) indextype is ctxsys.context;

create or replace function test_proc
 (v_id in varchar2, query_text in varchar2)
 return clob is
   temp_clob clob;
begin
   dbms_lob.createtemporary(temp_clob, TRUE);
   ctx_doc.set_key_type('PRIMARY_KEY');
   ctx_doc.markup
      (index_name => 'test1_index',
          textkey => v_id,
       text_query => query_text,
           restab => temp_clob,
        plaintext => false,
         starttag => '*foo*',
           endtag => '*bar*');
   return temp_clob;
end;
/
list 
show err

column output format a100

select test_proc('1', 'jump%') as output from dual;
select test_proc('2', 'jump%') as output from dual;
select test_proc('3', 'jump%') as output from dual;
select test_proc('4', 'jump%') as output from dual;

