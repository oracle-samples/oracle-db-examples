drop table jtest_tab;

create table jtest_tab (test_col varchar2(60));
insert all into jtest_tab values ('STOP MOLD VINYL/VINYL MO 8')
  into jtest_tab values ('STOP MOLD VINYL WITH END FLAP MO 10')
  select * from dual;

show errors

create type exp_tab is table of exp_rec index by binary_integer;
/
show errors

-- user must have explict "GRANT EXECUTE ON CTX_THES TO user" for this to
-- compile correctly (CTXAPP role is not sufficient)

create or replace function query_synonyms (instr varchar2)
  return varchar2 is
  work     varchar2(4000);
  synonyms ctx_thes.exp_tab;
begin
  ctx_thes.syn( synonyms, instr, 'JTEST_THES' );
  if synonyms.count = 0 then
    -- no match, return the search term with a % concatenated
    return instr || '%';
  else
    -- we're just going to return the first synonym (not the original term)
    -- a more sophisticated function would return multiple synonyms, possible
    -- with OR operators between them
    return synonyms(2).xphrase || '%';
  end if;
end;
/

show errors

create index jtest_tab_idx on jtest_tab (test_col) INDEXTYPE IS CTXSYS.CONTEXT;

exec ctx_thes.drop_thesaurus   ('jtest_thes')
exec ctx_thes.create_thesaurus ('jtest_thes')

exec ctx_thes.create_relation ('jtest_thes','MO', 'syn', 'MEDIUM OAK');

select * from jtest_tab where contains (test_col, 'MO') > 0;

select * from jtest_tab  where contains (test_col, query_synonyms('MO')) > 0;

select * from jtest_tab  where contains (test_col, query_synonyms('MEDIUM OAK')) > 0;

