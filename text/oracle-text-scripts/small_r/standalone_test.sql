set echo on


-- Run this on RAC node 1:

connect / as sysdba

drop user testuser cascade;

grant connect,resource,ctxapp,unlimited tablespace to testuser identified by testuser;

connect testuser/testuser

create table testtable (x varchar2(2000));

begin
  for i in 1..70500 loop
    insert into testtable values ('hello'||i);
  end loop;
end;
/

create index testindex on testtable(x) indextype is ctxsys.context;

select row_no, length(data) from dr$testindex$r;

-- Now run this on RAC node 2

connect testuser/testuser

create table testtable (x varchar2(2000));

begin
  for i in 70500..7100 loop
    insert into testtable values ('hello'||i);
  end loop;
end;
/

exec ctx_ddl.sync_index('testindex')

select row_no, length(data) from dr$testindex$r;

-- Now run this on RAC node 1

connect / as sysdba

exec sys.small_r_convert.convert_index('testuser', 'testindex')

-- And back to RAC node 2 for this:

connect testuser/testuser

select row_no, length(data) from dr$testindex$r;

begin
  for i in 71001..105001 loop
    insert into testtable values ('hello'||i);
  end loop;
end;
/

commit;

exec ctx_ddl.sync_index('testindex')

select row_no, length(data) from dr$testindex$r;

