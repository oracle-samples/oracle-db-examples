set serverout on

drop table mytable;
create table mytable (id number primary key, text varchar2(2000));
insert into mytable values (1, 'the quick brown fox jumps over the lazy dog');
create index myindex on mytable(text) indextype is ctxsys.context;

declare
  type token_rec is record (
    token varchar2(64),
    offset number,
    length number
  );
 type token_tab is table of token_rec index by binary_integer;
 the_tokens ctx_doc.token_tab;
begin
 ctx_doc.tokens('myindex','1',the_tokens);
 for i in 1..the_tokens.count loop
  dbms_output.put_line(
                      ' offset:' || the_tokens(i).offset
                    ||' length:' || the_tokens(i).length
                    ||' token:'  || the_tokens(i).token
                    );
  end loop;
end;
/

