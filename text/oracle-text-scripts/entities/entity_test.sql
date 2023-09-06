set serveroutput on

drop table test2;
create table test2 (text varchar2(2000));
insert into test2 values ('The quick brown øystein jumps over the lazy dog');
commit;

exec ctxsys.ctx_entity.drop_extract_policy('TEST_EE_POLICY')
exec ctxsys.ctx_entity.create_extract_policy('TEST_EE_POLICY', null, false, false)

REM at this point run: ctxload -user roger/roger -extract -name test_ee_policy -file test2.dat

EXEC CTX_ENTITY.COMPILE('TEST_EE_POLICY')

DECLARE
  mydocs CLOB;
  myresults CLOB;
BEGIN
    SELECT text INTO mydocs FROM test2;
    DBMS_OUTPUT.put_line('Input: ' || mydocs);
    CTX_ENTITY.EXTRACT('TEST_EE_POLICY', mydocs, null, myresults);
    DBMS_OUTPUT.put_line(myresults);
END;
/
