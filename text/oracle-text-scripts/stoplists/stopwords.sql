drop table sw;
create table sw (key number primary key, text varchar2(200));

insert into sw values (1, 'the elephant ate the antelope in the forest');

create index swi on sw(text) indextype is ctxsys.context;

set serverout on

 declare
    the_tokens ctx_doc.token_tab;
  begin
    ctx_doc.set_key_type ('PRIMARY_KEY');
    ctx_doc.tokens('swi','1',the_tokens);
    for i in 1..the_tokens.count loop
  	 dbms_output.put_line(the_tokens(i).token);
    end loop;
  end;
/ 
