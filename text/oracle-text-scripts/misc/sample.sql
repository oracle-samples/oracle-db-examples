connect system/oracle

drop user sampleuser cascade;

create user sampleuser identified by sampleuser default tablespace users temporary tablespace temp;

grant connect,resource,ctxapp to sampleuser;

alter user sampleuser quota unlimited on users;

connect sampleuser/sampleuser

CREATE TABLE CUSTOMERS
( ID                  NUMBER(8)            NOT NULL,
  FNAME               VARCHAR2(20)         NOT NULL,
  SNAME               VARCHAR2(65)         NOT NULL,
  MNAME               VARCHAR2(20),
  TITLE               VARCHAR2(8),
  DOB                 DATE);

CREATE TABLE ADDRESS_LINK
( ID                   NUMBER(8)                 NOT NULL,
  CUS_ID               NUMBER(8)                NOT NULL,
  PROP_ID              NUMBER(8)                NOT NULL,
  DATE_FROM            DATE                     NOT NULL,
  DATE_TO              DATE);
  

CREATE TABLE PROPERTY
( ID                        NUMBER(8)           NOT NULL,
  HOUSE_NO                  VARCHAR2(5),
  STREET                    VARCHAR2(100),
  POSTCODE                  VARCHAR2(12),
  ADDRESS_LABEL             VARCHAR2(750));

Insert into CUSTOMERS
   (ID, FNAME, SNAME, MNAME, TITLE)
 Values
   (6, 'ASH', 'NATHU', 'MUMBAI', 'DR');
Insert into CUSTOMERS
   (ID, FNAME, SNAME, MNAME, TITLE)
 Values
   (7, 'COOKIE', 'MONSTER', 'EATER', 'MR');
Insert into CUSTOMERS
   (ID, FNAME, SNAME, MNAME, TITLE, 
    DOB)
 Values
   (1, 'MINI', 'MOUSE', 'MICKEY', 'MRS', 
    TO_DATE('07/31/1933 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into CUSTOMERS
   (ID, FNAME, SNAME, TITLE, DOB)
 Values
   (3, 'FROGGLE', 'REED', 'MR', TO_DATE('06/25/1986 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into CUSTOMERS
   (ID, FNAME, SNAME, TITLE, DOB)
 Values
   (4, 'LEENA', 'RIPPLE', 'MRS', TO_DATE('03/23/1970 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into CUSTOMERS
   (ID, FNAME, SNAME, MNAME, TITLE, 
    DOB)
 Values
   (5, 'KERRY', 'SINGLETON', 'PARIS', 'MISS', 
    TO_DATE('01/08/1991 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into CUSTOMERS
   (ID, FNAME, SNAME)
 Values
   (2, 'CLARK', 'KENT');
COMMIT;

Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM)
 Values
   (902, 6, 7000, TO_DATE('06/21/2006 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM)
 Values
   (903, 7, 4000, TO_DATE('08/23/2007 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM, DATE_TO)
 Values
   (100, 1, 1000, TO_DATE('02/01/2000 08:29:16', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('01/02/2010 12:29:16', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM, DATE_TO)
 Values
   (300, 3, 3000, TO_DATE('09/08/2005 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('06/20/2006 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM, DATE_TO)
 Values
   (600, 4, 6000, TO_DATE('08/01/2000 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('12/03/2000 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM, DATE_TO)
 Values
   (700, 4, 7000, TO_DATE('12/04/2000 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('06/20/2006 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM)
 Values
   (800, 4, 8000, TO_DATE('01/23/2006 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM, DATE_TO)
 Values
   (900, 5, 9000, TO_DATE('08/18/1971 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('08/02/2004 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM, DATE_TO)
 Values
   (901, 5, 10000, TO_DATE('08/02/2004 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('06/03/2007 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM)
 Values
   (200, 2, 2000, TO_DATE('11/14/2001 18:10:07', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM, DATE_TO)
 Values
   (400, 3, 4000, TO_DATE('04/01/2004 00:00:00', 'MM/DD/YYYY HH24:MI:SS'), TO_DATE('06/20/2006 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
Insert into ADDRESS_LINK
   (ID, CUS_ID, PROP_ID, DATE_FROM)
 Values
   (500, 3, 5000, TO_DATE('11/07/2005 00:00:00', 'MM/DD/YYYY HH24:MI:SS'));
COMMIT;

Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (1000, '12', 'ELM STREET', 'LS1 2EW', '12, ELM STREET, LS1 2EW');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (2000, '122', 'HIGH ROAD', 'EW8 9RR', '122, HIGH ROAD, EW8 9RR');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (3000, '3', 'PARK AVENUE', 'M10 4RT', '3, PARK AVENU, M10 4RT');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (4000, '99', 'KING STREET', 'LE3 5TR', '99, KING STREET, LE3 5TR');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (5000, '88', 'URBAN CLOSE', 'P12 3ER', '88, URBAN CLOSE, P12 3ER');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (6000, '50', 'TWIN STREET', 'K11 6TY', '50, TWIN STREET, K11 6TY');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (7000, '34', 'DAIL AVENUE', 'D9 3DD', '34, DAIL AVENUE, D9 3DD');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (8000, '45', 'ELM STREET', 'LS1 2EW', '45, ELM STREET, LS1 2EW');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (9000, '25', 'PARK AVENUE', 'M10 4RT', '25, PARK AVENU, M10 4RT');
Insert into PROPERTY
   (ID, HOUSE_NO, STREET, POSTCODE, ADDRESS_LABEL)
 Values
   (10000, '33', 'BRICK LANE', 'B12 2WQ', '33, BRICK LANE, B12 2WQ');
COMMIT;


-- create the user datastore procedure 
-- this collects customer name into a <fullname> field and multiple addresses into
-- individual <address> fields

create or replace procedure cust_datastore (rid in rowid, rclob in out nocopy clob) is
begin

  rclob := '';

  -- get the customer details first
  -- this "loop" will only execute once but it's simpler to code this way:
  for c in (
    select c.title ||' '|| c.fname ||' '|| c.mname ||' '|| c.sname as fullname,
           to_char( dob, 'DD-MON-YYYY') as dob
    from   customers    c
    where  c.rowid = rid
  ) loop
    rclob := rclob || '<fullname>' || c.fullname || '</fullname>' || 
                   || '<dob>' || c.dob || '</dob>' ||chr(10);
  end loop;

  -- second loop gets property details - there may be more than one of these per customer
  for c in (
    select p.house_no||' '||p.street||' '||p.postcode||'  '||p.address_label as address
    from   customers    c,
           address_link a,
           property     p
    where  c.rowid   = rid
    and    a.cus_id  = c.id
    and    a.prop_id = p.id 
  ) loop
    rclob := rclob || '<address>' || c.address || '</address>' || chr(10);
  end loop;

end cust_datastore;
/ 
list
show errors

exec ctx_ddl.create_preference('cust_ds', 'USER_DATASTORE')
exec ctx_ddl.set_attribute('cust_ds', 'PROCEDURE', 'cust_datastore')

exec ctx_ddl.create_section_group('cust_sg', 'AUTO_SECTION_GROUP')

create index cust_index on customers(fname) 
indextype is ctxsys.context
parameters ('datastore cust_ds section group cust_sg memory 100M')
/

-- We need triggers to make sure the index gets updated if 
-- any of the data referenced in the user datastore changes 
-- (don't need insert trigger on customers, since indexing will
--  always happen for new rows in the indexed table)

create or replace trigger cust_update_trigger
after update 
  on customers
  for each row
begin
  update customers c set c.fname = c.fname
  where  c.id = :new.id;
end;
/
show err

create or replace trigger addr_update_trigger
after insert or update 
  on address_link
  for each row
begin
  update customers c set c.fname = c.fname
  where  c.id = :new.cus_id;
end;
/
show err

create or replace trigger prop_update_trigger
after insert or update 
  on property
  for each row
begin
  update customers c set c.fname = c.fname
  where c.id in (
    select cust.id
    from   customers    cust,
           address_link a,
           property     p
    where p.id = :new.id
    and   p.id = a.prop_id
    and   c.id = a.cus_id );
end;
/
show err

-- check for errors from the user datastore

select * from ctx_user_index_errors;

-- try some queries

-- simple search in name
select * from customers
where contains (fname, 'nathu WITHIN fullname') > 0;

-- AND search in name
select * from customers 
where contains (fname, '(dr AND ash) WITHIN fullname') > 0;

-- anywhere search
select * from customers 
where contains (fname, 'mumbai') > 0;

-- phrase search in address
select * from customers
where contains (fname, '(brick lane) WITHIN address') > 0;

