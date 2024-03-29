-- CDB1_PDB1 -> CloudBank
-- CDB1_PDB2 -> BankA
-- CDB1_PDB2 -> BankB
-- CDB1_PDB3 -> CreditScore

-- SCRIPT TO CLEANUP THE DEMO AND DELETE ALL THE CREATED ACCOUNTS. NOTE: WE DO NOT DROP ANY PDB'S HERE.

set serveroutput on

alter session set container=cdb1_pdb2;
drop sequence admin.SEQ_ACCOUNTS_BANK_A_LOGS;
drop sequence admin.SEQ_ACCOUNT_NUMBER_BANK_A;
drop sequence admin.SEQ_CREDIT_CARD_NUMBER_BANK_A;
drop table admin.bankA cascade constraints;
drop table admin.bankA_book cascade constraints;
ALTER USER admin DEFAULT TABLESPACE users;
exec dbms_saga_adm.drop_participant('BankA');

DROP PUBLIC DATABASE LINK PDB1_LINK;
DROP PUBLIC DATABASE LINK PDB3_LINK;
DROP PUBLIC DATABASE LINK PDB4_LINK;


alter session set container=cdb1_pdb3;
drop sequence admin.SEQ_ACCOUNTS_BANK_B_LOGS;
drop sequence admin.SEQ_ACCOUNT_NUMBER_BANK_B;
drop sequence admin.SEQ_CREDIT_CARD_NUMBER_BANK_B;
drop table admin.bankB cascade constraints;
drop table admin.bankB_book cascade constraints;
ALTER USER admin DEFAULT TABLESPACE users;
exec dbms_saga_adm.drop_participant('BankB');

DROP PUBLIC DATABASE LINK PDB1_LINK;
DROP PUBLIC DATABASE LINK PDB2_LINK;
DROP PUBLIC DATABASE LINK PDB4_LINK;



alter session set container=cdb1_pdb4;
drop sequence admin.SEQ_CREDIT_SCORE_LOGS;
drop table admin.credit_score_db cascade constraints;
drop table admin.credit_score_book cascade constraints;
ALTER USER admin DEFAULT TABLESPACE users;
exec dbms_saga_adm.drop_participant('CreditScore');
DROP PUBLIC DATABASE LINK PDB2_LINK;
DROP PUBLIC DATABASE LINK PDB1_LINK;
DROP PUBLIC DATABASE LINK PDB3_LINK;



alter session set container=cdb1_pdb1;
drop sequence admin.SEQ_CLOUDBANK_CUSTOMER_ID;
drop trigger admin.trg_customer_id;
drop table admin.cloudbank_customer cascade constraints;
drop table admin.cloudbank_book cascade constraints;
ALTER USER admin DEFAULT TABLESPACE users;
exec dbms_saga_adm.drop_participant('CloudBank');
exec dbms_saga_adm.drop_coordinator('CloudBankCoordinator');	
exec dbms_saga_adm.drop_broker(broker_name => 'TEST');

DROP PUBLIC DATABASE LINK PDB2_LINK;
DROP PUBLIC DATABASE LINK PDB3_LINK;
DROP PUBLIC DATABASE LINK PDB4_LINK;