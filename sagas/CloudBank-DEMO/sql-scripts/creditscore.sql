set serveroutput on

-- CREATE PARTICIPANT
exec dbms_saga_adm.add_participant(participant_name=> 'CreditScore' ,dblink_to_broker => 'pdb1_link',mailbox_schema=> 'admin',broker_name=> 'TEST', dblink_to_participant=> 'pdb4_link');

CREATE SEQUENCE SEQ_CREDIT_SCORE_LOGS
  START WITH 1
  INCREMENT BY 1
  NOMAXVALUE;


-- TABLE TO HOLD ALL THE OSSN'S, NAME AND CREDIT_SCORES.
-- FOR ANY USER TO CREATE AN ACCOUNT THEY SHOULD HAVE THEIR SSN REGISTERED TO THIS TABLE>
CREATE TABLE credit_score_db (
  ossn VARCHAR2(50) PRIMARY KEY,
  full_name VARCHAR2(100),
  credit_score NUMBER,
  created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- TABLE TO HOLD ALL THE SAGA STATUS UPDATES PERTAINING TO THIS PARTICIPANT
CREATE TABLE credit_score_book (
  log_id NUMBER DEFAULT SEQ_CREDIT_SCORE_LOGS.NEXTVAL PRIMARY KEY,
  saga_id VARCHAR2(50),
  operationType VARCHAR2(20) CHECK (operationType IN ('VIEW', 'CREDIT_CHECK')),
  ossn VARCHAR2(50),
  ucid VARCHAR2(50),
  operation_status VARCHAR2(10) CHECK (operation_status IN ('PENDING', 'ONGOING', 'COMPLETED', 'FAILED')),
  read VARCHAR2(10)  DEFAULT 'FALSE' CHECK (read IN ('TRUE', 'FALSE')),
  created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- MOCK LIST OF OSSN MAPPED WITH USER NAME AND THEIR CREDIT SCORES.

INSERT INTO credit_score_db (ossn, full_name, credit_score, created_at)
VALUES ('OSN001', 'CUSTOMER 1', '740', DEFAULT);

INSERT INTO credit_score_db (ossn, full_name, credit_score, created_at)
VALUES ('OSN002', 'CUSTOMER 2', '800', DEFAULT);

INSERT INTO credit_score_db (ossn, full_name, credit_score, created_at)
VALUES ('OSN003', 'CUSTOMER 3', '620', DEFAULT);

INSERT INTO credit_score_db (ossn, full_name, credit_score, created_at)
VALUES ('OSN004', 'CUSTOMER 4', '700', DEFAULT);

INSERT INTO credit_score_db (ossn, full_name, credit_score, created_at)
VALUES ('OSN005', 'CUSTOMER 5', '630', DEFAULT);

INSERT INTO credit_score_db (ossn, full_name, credit_score, created_at)
VALUES ('OSN006', 'CUSTOMER 6', '790', DEFAULT);

INSERT INTO credit_score_db (ossn, full_name, credit_score, created_at)
VALUES ('OSN007', 'CUSTOMER 7', '650', DEFAULT);

INSERT INTO credit_score_db (ossn, full_name, credit_score, created_at)
VALUES ('OSN008', 'CUSTOMER 8', '500', DEFAULT);