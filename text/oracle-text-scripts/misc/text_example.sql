connect system/oracle

-- drop the user and all objects before starting - obviously will fail first time

drop user testuser cascade;

-- create a user

create user testuser identified by testuser;

-- user requires CTXAPP role to use some text functions

grant connect,resource,CTXAPP to testuser;

-- logon as that user

connect testuser/testuser

-- create the table
-- remove NVARCHAR columns as they didn't work

CREATE TABLE T_ICE_CUSTOMER(
    ICE_CUSTOMER_PK INTEGER  ,
    SOURCE_SYSTEM_NAME VARCHAR(15)  ,
    SOURCE_SYSTEM_BUS_KEY VARCHAR(30)  ,
    CTRY_CD VARCHAR(10)  ,
    CUSTOMER_NAME VARCHAR(200)  ,
    OCN_CD VARCHAR(50)  ,
    ICE_CONTEXT VARCHAR(30)  ,
    ICE_CONTENT VARCHAR(4000)  ,
    D_STATUS VARCHAR(30)  ,
    D_ACTIVE_DATE TIMESTAMP   ,
    DW_START_DATE TIMESTAMP   ,
    DW_END_DATE TIMESTAMP   ,
    DW_MODIFIED_DATE TIMESTAMP   ,
    DW_PATCH_INDICATOR INTEGER   ,
    DW_DELETE_INDICATOR INTEGER   ,
    DW_LATEST_INDICATOR INTEGER   ,
    DW_BATCH_NUMBER INTEGER   );

-- populate the table

insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7651876','XNG','VRS/PAR/EH-000793','FR','7651876','FRC9TR','CIRCUIT REFERENCE',' ~ CUST: xxxxx ~ OCN: FRC9TR ~ COLT CIRCUIT: VRS/PAR/EH-000793 ~ VRS/VRS/E7R000343 ~ CONTRACT ID:  050304069 ~ XNG CUSTOMER NAME: 9 TELECOM RESEAU ~ SITE ID: PAR02301/02_SITE EQT SDH/PDH ~ SITE NAME: FR_78140_RUE NIEUPORT_6_1SS_FT2 ~ SITE ADD: RUE NIEUPORT');
insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7650884','XNG','SUI/ZRH/E1X106716','CH','7650884','99644','CIRCUIT REFERENCE',' ~ CUST: xxxx~ OCN: 99644 ~ COLT CIRCUIT: SUI/ZRH/E1X106716 ~ SUI/ZRH/E1X106716 ~ CONTRACT ID:  080101561 ~ XNG CUSTOMER NAME: AG FUER FRUCHTHANDEL ~ SITE ID: BSL00473/01 ~ SITE NAME: CH_4142_ALIOTHSTR_32_1_SERV ~ SITE ADD: ALIOTHSTRASSE');
insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7645538','XNG','TRN/MIL/IA-115223','IT','7645538','676508','CIRCUIT REFERENCE',' ~ CUST: xxxx ~ OCN: 676508 ~ COLT CIRCUIT: TRN/MIL/IA-115223 ~ TRN/TRN/AA-000047 ~ CONTRACT ID:  021150359DN1/1 ~ XNG CUSTOMER NAME: AVV. FRANCESCA PEREGO STUDIO LEGALE PEREGO MOSETTI ~ SITE ID: TRN00387/01 ~ SITE NAME: IT_10128_VIA LEGNANO_28 ~ SITE ADD: VIA LEGNANO');
insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'4888569','XNG','MIL/MIL/E1P120277','IT','4888569','39922','CIRCUIT REFERENCE',' ~ CUST: xxxxx ~ OCN: 39922 ~ COLT CIRCUIT: MIL/MIL/E1P120277 ~ MIL/MIL/E7R060951 ~ CONTRACT ID:  080300131/1 ~ XNG CUSTOMER NAME: BLOOMBERG LP ~ SITE ID: MIL00373/02 ~ SITE NAME: IT_20121_VIA FILIPPO TURATI_9_4 ~ SITE ADD: TURATIVIA');
insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7639970','XNG','XBT/BOD/LE-084748','FR','7639970','FRCCOLT','CIRCUIT REFERENCE',' ~ CUST: xxxxx ~ OCN: FRCCOLT ~ COLT CIRCUIT: XBT/BOD/LE-084748 ~ XBT/BOD/E5S080420(FR) ~ CONTRACT ID:  INT070901533 ~ XNG CUSTOMER NAME: COLT(FR) ~ SITE ID: PAR99901/91_MALAKOFF ~ SITE NAME: FR_92240_RUE PIERRE VALETTE_23_RDC_NODE(FR) ~ SITE ADD: RUE PIERRE VALETTE');
insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7647130','XNG','XBT/PAR/E1X090950','','7647130','n/a','CIRCUIT REFERENCE',' ~ CUST: xxxx ~ OCN: N/A ~ COLT CIRCUIT: XBT/PAR/E1X090950 ~ PAR/XBT/E5S002388 ~ CONTRACT ID:  051002373 ~ XNG CUSTOMER NAME: DIRECT MEDICA ~ SITE ID: PAR02524/01_SITE VIA DSL ~ SITE NAME: FR_92100_DUPOINTDUJOURRUE_102_INC_INC ~ SITE ADD: RUE DU POINT DU JOUR');
insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7644270','XNG','XBT/PAR/E7P060784','','7644270','n/a','CIRCUIT REFERENCE',' ~ CUST: N/A ~ OCN: N/A ~ COLT CIRCUIT: XBT/PAR/E7P060784 ~ XBT/PAR/E7P060784 ~ CONTRACT ID:  080210629 ~ XNG CUSTOMER NAME: BT FRANCE ~ SITE ID: PAR02397/16_SDH/PDH LECAPITOLE ~ SITE NAME: FR_92000_AVENUE CHAMPS-PIERREUX_55_RDC_SALLE1 ~ SITE ADD: AVENUE DES CHAMPS PIERREUX LE CAPITOLE');
insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7646810','XNG','XPS/XBT/DL-072564','','7646810','n/a','CIRCUIT REFERENCE',' ~ CUST: N/A ~ OCN: N/A ~ COLT CIRCUIT: XPS/XBT/DL-072564 ~ XPS/XBT/DL-072564 ~ CONTRACT ID:  061102086 ~ XNG CUSTOMER NAME: COLT(FR) ~ SITE ID: PAR02269/01_CAA LOGNES ~ SITE NAME: FR_77185_BOULEVARD DU MANDINET_1_TRANS_SDM3 ~ SITE ADD: BOULEVARD LE MANDINET');
insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7645998','XNG','ZRH/ZRH/IA-119181','CH','7645998','4212061','CIRCUIT REFERENCE',' ~ CUST: xxxxx ~ OCN: 4212061 ~ COLT CIRCUIT: ZRH/ZRH/IA-119181 ~ ZRH/ZRH/E5R064177 ~ CONTRACT ID:  100602721 ~ XNG CUSTOMER NAME: PLENUM SECURITIES AG ~ SITE ID: ZRH01330/01 ~ SITE NAME: CH_8034_BELLERIVESTR_33_G_SERV ~ SITE ADD: BELLERIVESTRASSE');

-- create the text index (most basic form)

create index ice_content on t_ice_customer (ice_content)
indextype is ctxsys.context;

-- run a query

select ice_content from t_ice_customer where contains (ice_content, 'PAR99901') > 0;

-- add another row

insert into t_ice_customer (ICE_CUSTOMER_PK,SOURCE_SYSTEM_NAME,SOURCE_SYSTEM_BUS_KEY,CTRY_CD,CUSTOMER_NAME,OCN_CD,ICE_CONTEXT,ICE_CONTENT) values (
'7633058','XNG','XBT/XBT/LE-094293','','7633058','n/a','CIRCUIT REFERENCE',' ~ CUST: N/A ~ OCN: N/A ~ COLT CIRCUIT: XBT/XBT/LE-094293 ~ XBT/XBT/LE-094293 ~ CONTRACT ID:  N/A ~ XNG CUSTOMER NAME: COLT(FR) ~ SITE ID: PAR99901/91_MALAKOFF ~ SITE NAME: FR_92240_RUE PIERRE VALETTE_23_RDC_NODE(FR) ~ SITE ADD: RUE PIERRE VALETTE');

-- commit the change

commit;

-- run the query again - same results because the index isn't sync'ed

select ice_content from t_ice_customer where contains (ice_content, 'PAR99901') > 0;

-- sync the index

exec ctx_ddl.sync_index('ice_content')

-- run the query again - get an extra row

select ice_content from t_ice_customer where contains (ice_content, 'PAR99901') > 0;

-- now we're going to create a more complex index

drop index ice_content;

-- create an index preference that uses "printjoins"

exec ctx_ddl.create_preference( 'my_lexer_pref', 'basic_lexer')

exec ctx_ddl.set_attribute( 'my_lexer_pref', 'PRINTJOINS', '/_-')

-- create the index specifying the lexer preference we just created 
-- and an additional 'memory' parameter to use a larger memory pool for the index creation

create index ice_content on t_ice_customer (ice_content)
indextype is ctxsys.context
parameters ('lexer my_lexer_pref memory 100M');

-- this query won't work, because PAR99901 is no longer a full word

select ice_content from t_ice_customer where contains (ice_content, 'PAR99901') > 0;

-- but this will because it adds a wildcard

select ice_content from t_ice_customer where contains (ice_content, 'PAR99901%') > 0;

-- and this will because it uses the full word

select ice_content from t_ice_customer where contains (ice_content, 'PAR99901/91_MALAKOFF') > 0;

-- You can use ORs and ANDs within the contains

select ice_content from t_ice_customer where contains (ice_content, 'PAR99901/91_MALAKOFF AND PIERRE') > 0;

-- DON'T DO THIS!!! MUCH LESS EFFICIENT

select ice_content from t_ice_customer where contains (ice_content, 'PAR99901/91_MALAKOFF') > 0 and contains (ice_content, 'PIERRE') > 0;

-- DON'T DO THE ABOVE!!

-- punctuation is stripped from query if not in PRINTJOINS.
-- a series of words without AND/OR is treated as a phrase and must occur in that order
-- beware of special characters: minus is an operator and must be escaped

select ice_content from t_ice_customer where contains (ice_content, 'SITE NAME: FR_92000_AVENUE CHAMPS\-PIERREUX_55_RDC_SALLE1') > 0;
