drop table cust_catalog;
create table cust_catalog (
  id number(16) primary key,
  firstname varchar2(80),
  surname varchar2(80),
  birth varchar2(25),
  age numeric );
INSERT ALL
INTO cust_catalog VALUES ('1','John','Smith','Glasgow','52')
INTO cust_catalog VALUES ('2','Emaily','Johnson','Aberdeen','55')
SELECT * FROM DUAL;
EXEC CTX_DDL.DROP_PREFERENCE   ('my_datastore')
EXEC CTX_DDL.CREATE_PREFERENCE ('my_datastore', 'MULTI_COLUMN_DATASTORE')
EXEC CTX_DDL.SET_ATTRIBUTE ('my_datastore', 'COLUMNS', 'firstname, surname')
CREATE INDEX context_idx ON cust_catalog (firstname)
INDEXTYPE IS CTXSYS.CONTEXT PARAMETERS('datastore my_datastore');
set serverout on
declare
  markuptext clob;
begin
  ctx_doc.set_key_type( 'PRIMARY_KEY' );
  ctx_doc.markup( 'context_idx', '1', 'john OR smith', markuptext );
  dbms_output.put_line( markuptext );
end;
/
