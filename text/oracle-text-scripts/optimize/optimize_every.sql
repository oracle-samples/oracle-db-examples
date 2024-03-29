set echo on
drop table t;
create table t(c varchar2(2000));
insert into t values ('hello world');
create index i on t(c) indextype is ctxsys.context 
parameters ('sync(on commit) optimize (every "freq=secondly;interval=60")');

begin
  for i in 1..10 loop
    for k in 1..10 loop
      for j in 1..10 loop
        insert into t values ('a'||i||' b'||i||j||' c'||i||j||k);
        commit;
      end loop;
    end loop;
  end loop;
end;
/

-- check fragmentation. The 'A' tokens will have 100 rows in $I
column token_text format a30
select token_text, count(*) from dr$i$i group by token_text having count(*) > 1 order by count(*);

exec dbms_session.sleep(60)
-- after 60 seconds all the high-count 'A' tokens will be gone
select token_text, count(*) from dr$i$i group by token_text having count(*) > 1 order by count(*);

exec dbms_session.sleep(60)

-- after another 60 seconds the number of rows will be reduced by 10
select token_text, count(*) from dr$i$i group by token_text having count(*) > 1 order by count(*);
