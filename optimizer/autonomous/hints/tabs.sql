begin
  execute immediate 'drop table table2 purge';
exception
  when others then
    if sqlcode != -942 then
      raise;
    end if;
end;
/

begin
  execute immediate 'drop table table1 purge';
exception
  when others then
    if sqlcode != -942 then
      raise;
    end if;
end;
/

create table table1 (id number(10) primary key, num number(10), txt varchar2(50));

create table table2 (id number(10) primary key, t1id number(10), num number(10), txt varchar2(50),
                     constraint t1fk foreign key (t1id) references table1 (id));

begin
  for i in 1..1000
  loop
     insert into table1 values (i,i,'TABLE 1 '||i);
  end loop;
end;
/

insert into table2 values (1,1,10,'TABLE 2');

commit;

