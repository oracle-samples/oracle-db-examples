-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 19c
-- 
--   OML R Extensible - Feature Extraction via PCA  - dmrpcademo.sql
--   
--   Copyright (c) 2020 Oracle Corporation and/or its affilitiates.
--
--  The Universal Permissive License (UPL), Version 1.0
--
--  https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET linesize 140
SET LONG 10000
SET echo ON


-----------------------------------------------------------------------
--                            SET UP THE DATA
-----------------------------------------------------------------------

-- Cleanup old training data view for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP VIEW pca_build_v';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create a view for building PCA model
create view pca_build_v as
select cust_id, age, yrs_residence, affinity_card, bulk_pack_diskettes,
flat_panel_monitor, home_theater_package, bookkeeping_application, y_box_games  
from mining_data_build_v;

-----------------------------------------------------------------------
--                            BUILD A PCA MODEL
-----------------------------------------------------------------------

-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('RPCA_SH_FE_SAMPLE');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table and R scripts for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Rpca_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
sys.rqScriptDrop('RPCA_BUILD');
sys.rqScriptDrop('RPCA_SCORE');
sys.rqScriptDrop('RPCA_WEIGHT');
sys.rqScriptDrop('RPCA_DETAILS');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE Rpca_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

------------
-- R scripts
--
-- The R scripts are created by users using sys.rqScriptCreate to define
-- their own approaches in R for building FEATURE EXTRACTION models and 
-- scoring new data in ODM framework.
--
-- Here is the mapping between the R scripts and ODM functions/PROCs that
-- invoke and use the R scripts. Please refer to user guide for details.
--------------------------------------------------------------------------
-- ralg_build_function           -------   CREATE_MODEL 
-- ralg_score_function           -------   FEATURE_VALUE, FEATURE_SET
-- ralg_weight_function          -------   FEATURE_DETAILS
-- ralg_details_function         -------   CREATE_MODEL(to generate model view)
-- ralg_details_format           -------   CREATE_MODEL(to generate model view)

BEGIN
  INSERT INTO Rpca_sh_sample_settings VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
  
-- Our BUILD script here uses R's prcomp function to build a PCA model  
-- Predefined attribute dm$nfeat must be set on the generated R model to
-- indicate the number of features extracted by the model fit.
  sys.rqScriptCreate('RPCA_BUILD', 
    'function(dat) {
     mod <- prcomp(dat, retx = FALSE)
     attr(mod, "dm$nfeat") <- ncol(mod$rotation)
     mod}');

-- Our SCORE script here uses the predict method for prcomp to generate
-- the mapped feature values of the new data. It returns a data.frame
-- with each column representing a projected new feature.   
  sys.rqScriptCreate('RPCA_SCORE',
    'function(mod, dat) { 
     res <- predict(mod, dat)
     as.data.frame(res)}');

-- Our WEIGHT script here calculates the contribution of each attribute
-- to the specified feature. It returns a data.frame with each column
-- representing the weight of the corresponding attribute.
  sys.rqScriptCreate('RPCA_WEIGHT', 
    'function(mod, dat, feature) {
     feature <- as.numeric(feature)
     dat <- scale(dat, center = mod$center, scale = FALSE)
     v <- mod$rotation[, feature]
     as.data.frame(t(apply(dat, 1L, function(u) v*u)))}');

-- The DETAILS script, along with the FORMAT script below will be 
-- invoked during CREATE_MODEL. A model view will be generated with 
-- the output of the DETAILS script.                                                                            
-- Our DETAILS script returns a data.frame containing the standard 
-- deviation of the new features.           
  sys.rqScriptCreate('RPCA_DETAILS',
    'function(mod){
     data.frame(feature = seq(length(mod$sdev)), sd = mod$sdev)}');
    
  INSERT INTO Rpca_sh_sample_settings VALUES
  (dbms_data_mining.ralg_build_function, 'RPCA_BUILD');
  INSERT INTO Rpca_sh_sample_settings VALUES
  (dbms_data_mining.ralg_score_function, 'RPCA_SCORE');
  INSERT INTO Rpca_sh_sample_settings VALUES
  (dbms_data_mining.ralg_weight_function, 'RPCA_WEIGHT');
  INSERT INTO Rpca_sh_sample_settings VALUES
  (dbms_data_mining.ralg_details_function, 'RPCA_DETAILS');
  INSERT INTO Rpca_sh_sample_settings VALUES
  (dbms_data_mining.ralg_details_format, 
  'select 1 feature, 1 sd from dual');
END;
/


---------------------
-- CREATE A NEW MODEL
--
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'RPCA_SH_FE_SAMPLE',
    mining_function     => dbms_data_mining.feature_extraction,
    data_table_name     => 'PCA_BUILD_V',
    case_id_column_name => 'CUST_ID',
    settings_table_name => 'Rpca_sh_sample_settings');
END;
/


-------------------------
-- DISPLAY MODEL SETTINGS
--
column setting_name format a30
column setting_value format a40
select setting_name, setting_value from Rpca_sh_sample_settings
order by setting_name;

-------------------------
-- DISPLAY MODEL METADATA
--
column model_name format a20
column mining_function format a20
column algorithm format a20
select model_name, mining_function, algorithm from user_mining_models
where model_name = 'RPCA_SH_FE_SAMPLE';

------------------------
-- DISPLAY MODEL DETAILS
--
column partition_name format a20
select * from DM$VDRPCA_SH_FE_SAMPLE order by feature;


-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------
-- For a descriptive mining function like Feature Extraction, "Scoring"
-- involves providing the projected values of each feature.

-- List the PCA projection values of the top four features for 15 customers 
--
SELECT cust_id, round(FEATURE_VALUE(RPCA_SH_FE_SAMPLE, 1 USING *), 3) 
AS PROJV1, round(FEATURE_VALUE(RPCA_SH_FE_SAMPLE, 2 USING *), 3) 
AS PROJV2, round(FEATURE_VALUE(RPCA_SH_FE_SAMPLE, 3 USING *), 3) AS PROJV3,
round(FEATURE_VALUE(RPCA_SH_FE_SAMPLE, 4 USING *), 3) AS PROJV4
FROM mining_data_apply_v
WHERE cust_id <= 100015
ORDER BY cust_ID;

-- List the PCA projection values of the top three features for 10 customers 
-- using FEATURE_SET
--
SELECT cust_id, S.feature_id fid, round(S.value, 3) value 
FROM  (SELECT cust_id, FEATURE_SET(RPCA_SH_FE_SAMPLE USING *) fset
                FROM mining_data_apply_v v where cust_id <= 100010) T,
               TABLE(T.fset) S
WHERE S.feature_id <= 3
ORDER BY cust_id, fid;

-- List the 2 most important attributes for the top feature for each row 
-- for 10 new customers
--
column feat_det format a60
SELECT cust_id,
       FEATURE_DETAILS(RPCA_SH_FE_SAMPLE, 1, 2 USING *) feat_det
FROM mining_data_apply_v 
WHERE CUST_ID < = 100010
ORDER BY cust_id;



-----------------------------------------------------------------------
--                       BUILD A PCA MODEL BY PARTITION
-----------------------------------------------------------------------
-- This example illustrates building a partitioned PCA model by 
-- a specified partition column in parallel. We use the same settings 
-- table in the above example with an additional partition column
-- setting.


-- Cleanup old training data view for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP VIEW pca_build_partition_v';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create a view for building PCA models by partition in parallel
create view pca_build_partition_v as
select /*+parallel */ cust_id, cust_gender, age, yrs_residence, 
affinity_card, bulk_pack_diskettes, flat_panel_monitor, 
home_theater_package, bookkeeping_application, y_box_games  
from mining_data_build_v;

-- Check the customer gender distribution of the training data
select cust_gender gender, count(*) CNT 
from pca_build_partition_v group by cust_gender;

-- Specify the column CUST_GENDER as the partition column in
-- setting table
INSERT INTO Rpca_sh_sample_settings VALUES
('ODMS_PARTITION_COLUMNS', 'CUST_GENDER');


-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('RPCA_SH_FE_SAMPLE_P');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

----------------------------------
-- CREATE A NEW MODEL BY PARTITION
--
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
    model_name          => 'RPCA_SH_FE_SAMPLE_P',
    mining_function     => dbms_data_mining.feature_extraction,
    data_table_name     => 'PCA_BUILD_PARTITION_V',
    case_id_column_name => 'CUST_ID',
    settings_table_name => 'Rpca_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
--
select setting_name, setting_value from Rpca_sh_sample_settings
order by setting_name;


-------------------------
-- DISPLAY MODEL METADATA
--
select model_name, mining_function, algorithm from user_mining_models
where model_name = 'RPCA_SH_FE_SAMPLE_P';


------------------------------
-- DISPLAY MODEL PARTITION INFO
--
column model_name format a20
column partition_name format a15
column column_name format a12
column column_value format a10

select * from user_mining_model_partitions
where model_name= 'RPCA_SH_FE_SAMPLE_P'
order by partition_name;


------------------------------------
-- DISPLAY MODEL DETAILS BY PARTITION
--
select * from DM$VDRPCA_SH_FE_SAMPLE_P order by partition_name, feature;


-----------------------------------------------------------------------
--                     APPLY THE PARTITIONED MODEL
-----------------------------------------------------------------------

-- List the corresponding partition names of the first 10 new customers
column cust_gender format a15
select cust_id, cust_gender, age, 
       ora_dm_partition_name(RPCA_SH_FE_SAMPLE_P using *) partition_name
from mining_data_apply_v
where cust_id < = 100010
order by cust_id;


-- List the PCA projection values of the top two features for 15 customers
-- using the partitioned model. 
-- Each row of new data automatically uses its corresponding partitioned
-- model for scoring.
--
SELECT cust_id, round(FEATURE_VALUE(RPCA_SH_FE_SAMPLE_P, 1 USING *), 3) 
AS PROJV1, round(FEATURE_VALUE(RPCA_SH_FE_SAMPLE_P, 2 USING *), 3) 
AS PROJV2
FROM mining_data_apply_v
WHERE cust_id <= 100015
ORDER BY cust_ID;
