set serveroutput on

-- CREATE BROKER, COORDINATOR AND PARTICIPANT. THESE ENTITIES SHOULD BE CREATED IN THIS PARTICULAR ORDER.
exec dbms_saga_adm.add_broker(broker_name => 'TEST', broker_schema => 'admin');
exec dbms_saga_adm.add_coordinator(coordinator_name => 'CloudBankCoordinator', mailbox_schema => 'admin', broker_name => 'TEST', dblink_to_coordinator => 'pdb1_link');
exec dbms_saga_adm.add_participant(participant_name => 'CloudBank', coordinator_name => 'CloudBankCoordinator' , dblink_to_broker => 'pdb1_link' , mailbox_schema => 'admin' , broker_name => 'TEST', dblink_to_participant => 'pdb1_link');

CREATE SEQUENCE SEQ_CLOUDBANK_CUSTOMER_ID
  START WITH 1
  INCREMENT BY 1
  NOMAXVALUE;

CREATE SEQUENCE SEQ_CLOUDBANK_LOG_ID
  START WITH 1
  INCREMENT BY 1
  NOMAXVALUE;

-- TABLE TO HOLD THE CUSTOMER DETAILS
CREATE TABLE cloudbank_customer (
  customer_id VARCHAR2(50) UNIQUE,
  password VARCHAR2(50),
  full_name VARCHAR2(100),
  address VARCHAR2(255),
  phone VARCHAR2(20),
  email VARCHAR2(100) UNIQUE,
  ossn VARCHAR2(10) NOT NULL,
  bank VARCHAR2(10) NOT NULL CHECK (bank IN ('BankA', 'BankB')),
  created_at TIMESTAMP DEFAULT SYSTIMESTAMP,
  PRIMARY KEY(email,ossn)
);

CREATE OR REPLACE TRIGGER trg_customer_id
  BEFORE INSERT ON cloudbank_customer
    FOR EACH ROW
  BEGIN
      :NEW.customer_id := 'ORACLE' || TO_CHAR(:NEW.customer_id, 'FM000');
  END;
/

-- TABLE TO HOLD ALL THE SAGA STATUS UPDATES PERTAINING TO THIS PARTICIPANT
CREATE TABLE cloudbank_book (
  log_id NUMBER DEFAULT SEQ_CLOUDBANK_LOG_ID.NEXTVAL PRIMARY KEY,
  saga_id VARCHAR2(50),
  ucid VARCHAR2(50) REFERENCES cloudbank_customer(customer_id),
  operationType VARCHAR2(18) CHECK (operationType IN ('VIEW', 'TRANSFER', 'NEW_ACCOUNT','NEW_CREDIT_CARD')),
  transfer_type VARCHAR2(20) CHECK (transfer_type IN ('INTER-BANK', 'INTRA-BANK', 'null')),
  operation_status VARCHAR2(10) CHECK (operation_status IN ('PENDING', 'ONGOING', 'COMPLETED', 'FAILED')),
  read VARCHAR2(10)  DEFAULT 'FALSE' CHECK (read IN ('TRUE', 'FALSE')),
  created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- MOCK LIST OF CUSTOMERS FOR THE CLOUDBANK
INSERT INTO cloudbank_customer (customer_id, password, full_name, address, phone, email, ossn, bank, created_at)
VALUES (SEQ_CLOUDBANK_CUSTOMER_ID.NEXTVAL,'cb1', 'CUSTOMER 1', 'CUSTOMER 1 HOME, CALIFORNIA', '555-1234', 'customer1@example.com', 'OSN001', 'BankA', DEFAULT);

INSERT INTO cloudbank_customer (customer_id, password, full_name, address, phone, email, ossn, bank, created_at)
VALUES (SEQ_CLOUDBANK_CUSTOMER_ID.NEXTVAL,'cb2', 'CUSTOMER 2', 'CUSTOMER 2 HOME, CALIFORNIA', '555-5678', 'customer2@example.com', 'OSN002', 'BankB', DEFAULT);

INSERT INTO cloudbank_customer (customer_id, password, full_name, address, phone, email, ossn, bank, created_at)
VALUES (SEQ_CLOUDBANK_CUSTOMER_ID.NEXTVAL,'cb3', 'CUSTOMER 3', 'CUSTOMER 3 HOME, CALIFORNIA', '555-9012', 'customer3@example.com', 'OSN003', 'BankB', DEFAULT);

INSERT INTO cloudbank_customer (customer_id, password, full_name, address, phone, email, ossn, bank, created_at)
VALUES (SEQ_CLOUDBANK_CUSTOMER_ID.NEXTVAL,'cb4', 'CUSTOMER 4', 'CUSTOMER 4 HOME, CALIFORNIA', '555-3456', 'customer4@example.com', 'OSN004', 'BankA', DEFAULT);
