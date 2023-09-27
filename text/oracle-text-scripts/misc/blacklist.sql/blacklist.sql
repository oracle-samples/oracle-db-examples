DROP TABLE blacklist;
CREATE TABLE blacklist (name VARCHAR2(4000));

DROP TABLE customer;
CREATE TABLE customer (surname VARCHAR2(40), name VARCHAR2(40), patronymic VARCHAR2(40), full_name VARCHAR2(120));

INSERT INTO blacklist VALUES ('BLUE SKY AVIATION CO FZE');
INSERT INTO blacklist VALUES ('JSC V. TIKHOMIROV SCIENTIFIC RESEARCH INSTITUTE OF INSTRUMENT DESIGN');

INSERT INTO customer (full_name) VALUES ('Blue Sky Aviation Service LLC');
INSERT INTO customer (full_name) VALUES ('Tihomirov research institute');

exec ctx_ddl.drop_preference     ('cust_ds')
exec ctx_ddl.create_preference   ('cust_ds', 'MULTI_COLUMN_DATASTORE') 
exec ctx_ddl.set_attribute       ('cust_ds', 'COLUMNS', 'full_name')

exec ctx_ddl.drop_section_group  ('cust_sg')
exec ctx_ddl.create_section_group('cust_sg', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_ndata_section   ('cust_sg', 'full_name', 'full_name')

CREATE INDEX cust_index ON customer(full_name) INDEXTYPE IS ctxsys.context 
PARAMETERS ('datastore cust_ds section group cust_sg');

set serveroutput on

declare
  cust_name varchar2(120);
begin
  for b in ( select name from blacklist ) loop
     dbms_output.put_line('Searching for blacklisted customer: ' || b.name);
     for c in ( select score(1) scr, full_name 
                from customer 
                where contains (full_name, 'NDATA(full_name, ' ||b.name|| ')', 1) > 0 ) loop
       dbms_output.put_line('>>    Found customer: "' || c.full_name || '" Confidence: ' || c.scr);
     end loop;
  end loop;
end;
/

