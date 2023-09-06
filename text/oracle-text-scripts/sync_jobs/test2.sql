set echo on

connect system/password

-- create tablespace testtemp datafile 'testtemp.tbs' size 1g autoextend on;

drop user testuser cascade;

create user testuser identified by testuser default tablespace testtemp temporary tablespace temp quota unlimited on testtemp;

grant connect,resource,ctxapp to testuser;

connect testuser/testuser

create table test (id number, text clob)
partition by range (id)
(
 partition p1 values less than (201),
 partition p2 values less than (401),
 partition p3 values less than (601),
 partition p4 values less than (801),
 partition p5 values less than (1001)
);

set timing on

create index testindex on test(text) indextype is ctxsys.context parameters('sync(on commit)') local;

declare
  str clob;
begin
  -- 1000 rows
  for k in 1 .. 1000 loop
    str := ' ';
    -- 400 words per row
    for i in 1..400 loop
      str := str || ' word' || i;
    end loop;
    insert into test values (k, str);
    commit;
  end loop;
end;
/

prompt press enter>

exec ctx_ddl.optimize_index(idx_name => 'testindex', optlevel => 'FULL', part_name => 'p1', parallel_degree => 2)

