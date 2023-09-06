set serverout on 
set define off
set echo on

exec ctxsys.ctx_entity.drop_extract_policy('TEST_EE_POLICY')

exec ctxsys.ctx_entity.create_extract_policy('TEST_EE_POLICY', null, false, false)

host ctxload -user roger/roger -extract -name test_ee_policy -file test2.dat

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
