set serverout on 
set define off

exec ctxsys.ctx_entity.drop_extract_policy('REFID_1_TEST_CASE')

EXEC CTXSYS.CTX_ENTITY.CREATE_EXTRACT_POLICY('REFID_1_TEST_CASE', null, false, false);

DECLARE
  rule VARCHAR2(4000) := '<rule>'                                          ||
'<expression>' ||
         '(([a-c])([[:digit:]]))'     ||
'</expression>' ||
      '<type refid="2">xTestRefid1</type>'                          ||
    '</rule>';
BEGIN
  CTXSYS.CTX_ENTITY.ADD_EXTRACT_RULE('REFID_1_TEST_CASE',1,rule);
END;
/

EXEC CTX_ENTITY.COMPILE('REFID_1_TEST_CASE');

DECLARE
  mydocs CLOB;
  myresults CLOB;
BEGIN
    SELECT 'Test a1 b4 c6 ' INTO mydocs FROM DUAL;
    DBMS_OUTPUT.put_line('Input: ' || mydocs);
    CTX_ENTITY.EXTRACT('REFID_1_TEST_CASE', mydocs, null, myresults);
    DBMS_OUTPUT.put_line(myresults);
END;
/
