drop table cust_catalog
/

create table cust_catalog (
id number(16),
firstname varchar2(80),
surname varchar2(80),
birth varchar2(25),
age numeric )
/

INSERT ALL
INTO cust_catalog VALUES ('1','John','Smith','Glasgow','52')
INTO cust_catalog VALUES ('2','Emaily','Johnson','Aberdeen','55')
INTO cust_catalog VALUES ('3','David','Miles','Leeds','53')
INTO cust_catalog VALUES ('4','Keive','Johnny','London','45')
INTO cust_catalog VALUES ('5','Jenny','Smithy','Norwich','35')
INTO cust_catalog VALUES ('6','Andy','Mil','Aberdeen','63')
INTO cust_catalog VALUES ('7','Andrew','Smith','London','64')
INTO cust_catalog VALUES ('8','John','Smith','London','54')
INTO cust_catalog VALUES ('9','John','Henson','London','56')
INTO cust_catalog VALUES ('10','John','Mil','London','58')
INTO cust_catalog VALUES ('11','Jon','Smith','Glasgow','57')
INTO cust_catalog VALUES ('12','Jen','Smith','Glasgow','60')
INTO cust_catalog VALUES ('13','Chris','Smith','Glasgow','59')
SELECT * FROM DUAL
/

EXEC CTX_DDL.DROP_PREFERENCE   ('your_datastore')
EXEC CTX_DDL.CREATE_PREFERENCE ('your_datastore', 'MULTI_COLUMN_DATASTORE')
EXEC CTX_DDL.SET_ATTRIBUTE ('your_datastore', 'COLUMNS', 'firstname, surname')

EXEC CTX_DDL.DROP_SECTION_GROUP   ('your_sec')
EXEC CTX_DDL.CREATE_SECTION_GROUP ('your_sec', 'BASIC_SECTION_GROUP')
EXEC CTX_DDL.ADD_FIELD_SECTION ('your_sec', 'firstname', 'firstname', TRUE)
EXEC CTX_DDL.ADD_FIELD_SECTION ('your_sec', 'surname', 'surname', TRUE)

CREATE INDEX context_idx ON cust_catalog (firstname)
INDEXTYPE IS CTXSYS.CONTEXT PARAMETERS('datastore your_datastore section group your_sec')
/

CREATE OR REPLACE TRIGGER your_upd_trigger 
 BEFORE UPDATE ON cust_catalog
  FOR EACH ROW
BEGIN
  IF :new.surname != :old.surname THEN
    :new.firstname := :new.firstname;
  END IF;
END;
/
show err
list


SELECT * FROM cust_catalog WHERE contains (firstname, '(john WITHIN firstname) or (miles WITHIN surname) or (jen)') > 0
/

UPDATE cust_catalog SET surname = 'Smythe' WHERE id = 1;

EXEC ctx_ddl.sync_index('context_idx')

SELECT * FROM cust_catalog WHERE contains (firstname, '(smythe WITHIN surname)') > 0;



