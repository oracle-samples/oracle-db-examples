--##################################################################
--##
--## Oracle Machine Learning for R Vignette 
--## 
--## Extensibility for R Models
--##
--## Copyright (c) 2020 Oracle Corporation                          
--##
--## The Universal Permissive License (UPL), Version 1.0
--## 
--## https://oss.oracle.com/licenses/upl/
--##
--###################################################################

-- Register a new GLM algorithm and use it to create models
-- Cleanup any prior output tables/scripts/models 
  
BEGIN EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_CL';  
EXCEPTION WHEN OTHERS THEN NULL; END;
/
  
BEGIN DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_CLASSIFICATION');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
  
BEGIN
DBMS_DATA_MINING.drop_algorithm(
  ALGORITHM_NAME => 't1',
  CASCADE => TRUE);
END;
/
  
-- Register the Algorithm 
  
BEGIN
DBMS_DATA_MINING.register_algorithm(
  ALGORITHM_NAME         => 't1',
  algorithm_metadata     => 
    '{"function_language":"R",
  "mining_function" : { "mining_function_name" : "CLASSIFICATION",
  "build_function" : {"function_body":
  "function(dat, formula, keep.model) { set.seed(1234); mod <- glm(formula = formula(formula), data=dat, family=binomial(logit), model = as.logical(keep.model)); mod}"},
  
  "score_function" : {"function_body":
  "function(mod, dat) { res <- predict(mod, newdata = dat, type=''response''); res2=data.frame(1-res, res); names(res2) <- c(''0'', ''1''); res2}"}},
  "algo_setting" : [{"name" : "ralg_parameter_keep.model", "data_type" : "integer","value" : "0", "optional" : "TRUE", "min_value" : {"min_value": "0", "inclusive": "TRUE"}, "max_value" : {"max_value": "1", "inclusive": "TRUE"}}]
  }',
    algorithm_description  => 't1');
END;
/
  
-- Model Settings
  
CREATE TABLE GLM_RDEMO_SETTINGS_CL (
    setting_name  VARCHAR2(30),
    setting_value VARCHAR2(4000));

BEGIN
INSERT INTO GLM_RDEMO_SETTINGS_CL VALUES
('ALGO_EXTENSIBLE_LANG', 'R');
END;
/
  
BEGIN
INSERT INTO GLM_RDEMO_SETTINGS_CL 
VALUES(dbms_data_mining.algo_name, 't1');
END;
/
  
BEGIN
INSERT INTO GLM_RDEMO_SETTINGS_CL 
VALUES(dbms_data_mining.r_formula, 'AGE + EDUCATION + HOUSEHOLD_SIZE + OCCUPATION');
END;
/
  
BEGIN
INSERT INTO GLM_RDEMO_SETTINGS_CL 
VALUES('ralg_parameter_keep.model', 1);
END;
/
  
--#-- Build the model using the registered build function

BEGIN
DBMS_DATA_MINING.CREATE_MODEL(
  model_name          => 'GLM_RDEMO_CLASSIFICATION',
  mining_function     => dbms_data_mining.classification,
  data_table_name     => 'mining_data_build_v',
  case_id_column_name => 'CUST_ID',
  target_column_name  => 'AFFINITY_CARD',
  settings_table_name => 'GLM_RDEMO_SETTINGS_CL');
END;
/
  
--#-- Score data using the model's registered score function

SELECT CUST_ID, AFFINITY_CARD as AFFINITY_CARD_act, 
PREDICTION(GLM_RDEMO_CLASSIFICATION USING *) AFFINITY_CARD_pred,
round(PREDICTION_PROBABILITY(GLM_RDEMO_CLASSIFICATION USING *), 3) 
as AFFINITY_CARD_prob 
FROM mining_data_apply_v where CUST_ID <= 100010 
order by CUST_ID;


--#-- Clean up   
  
  BEGIN
DBMS_DATA_MINING.drop_algorithm(
  ALGORITHM_NAME => 't1',
  CASCADE => TRUE);
END;
/
  
--#-- End of Script