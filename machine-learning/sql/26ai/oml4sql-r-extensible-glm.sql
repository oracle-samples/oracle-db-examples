-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   OML R Extensible - Generalized Linear Model Algorithm - dmrglmdemo.sql  
--   Copyright (c) 2026 Oracle Corporation and/or its affiliates.
--
--   The Universal Permissive License (UPL), Version 1.0
--   https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
SET LONG 10000

-------------------------------------------------------------------------------
--                         GLM REGRESSION DEMO
-------------------------------------------------------------------------------

-- Explanation:
-- This demo shows how to implement the GLM regression algorithm in Oracle Data 
-- Mining using R glm algorithm.

-- Cleanup old output tables/scripts/models for repeat runs -------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_RE';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

Begin
  sys.rqScriptDrop('GLM_RDEMO_BUILD_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_SCORE_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_DETAILS_REGRESSION', v_silent => TRUE);
End;
/


-- Model Settings -------------------------------------------------------------


Begin
-- Build R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named GLM_RDEMO_BUILD_REGRESSION is defined. This 
-- function builds and returns a GLM regression model using R glm algorithm. 
-- User can also choose other R algorithm to implement the GLM regression 
-- algorithm.

  sys.rqScriptCreate('GLM_RDEMO_BUILD_REGRESSION', 'function(dat, wgt) {
   set.seed(1234); 
   mod <- glm(AGE ~ ., data = dat, weights = wgt); mod}');

-- Score R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to do the scoring using the built
-- model. For example, here a script named GLM_RDEMO_SCORE_REGRESSION is defined. 
-- This function creates and returns an R data.frame containing the target 
-- predictions with se.fit on. User can also define other PREDICTION functions
-- with different settings.

  sys.rqScriptCreate('GLM_RDEMO_SCORE_REGRESSION', 'function(mod, dat) {
   res <- predict(mod, newdata = dat, se.fit = TRUE); 
   data.frame(fit=res$fit, se=res$se.fit, df=summary(mod)$df[1L]) }');

-- Detail R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named GLM_RDEMO_DETAILS_REGRESSION
-- is defined. This function creates and returns an R data.frame containing the 
-- attribute coefficients of the built model. User can also display other details.

  sys.rqScriptCreate('GLM_RDEMO_DETAILS_REGRESSION', 'function(object) {
   mod <- object; 
   data.frame(name=names(mod$coefficients), 
   coef=mod$coefficients)}');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- attribute names and the corresponding coefficients.

-- Column YRS_RESIDENCE has row weights.

End;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------

-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- GLM_RDEMO_BUILD_REGRESSION will be used to create the GLM regression model 
-- GLM_RDEMO_REGRESSION using dataset mining_data_build_v.


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_REGRESSION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'GLM_RDEMO_BUILD_REGRESSION';
  v_setlst(dbms_data_mining.ralg_score_function) := 'GLM_RDEMO_SCORE_REGRESSION';
  v_setlst(dbms_data_mining.ralg_details_function) := 'GLM_RDEMO_DETAILS_REGRESSION';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(200)) attr, 1 coef FROM dual';
  v_setlst('ODMS_ROW_WEIGHT_COLUMN_NAME') := 'YRS_RESIDENCE';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'GLM_RDEMO_REGRESSION',
    mining_function     => dbms_data_mining.regression,
    data_query          => 'SELECT * FROM mining_data_build_v',
    case_id_column_name => 'CUST_ID',
    target_column_name  => 'AGE',
    set_list            => v_setlst
    );
END;
/

-----------------------------------------------------------------------
-- CREATE_MODEL EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL is useful for application development when model settings
-- are separated into a settings table for convenient updating.
-- This build intentionally replaces the model created by the preceding CREATE_MODEL2 example.

-- Drop settings table if it exists
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_RE';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_REGRESSION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE GLM_RDEMO_SETTINGS_RE (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO GLM_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO GLM_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'GLM_RDEMO_BUILD_REGRESSION');
    INSERT INTO GLM_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_score_function, 'GLM_RDEMO_SCORE_REGRESSION');
    INSERT INTO GLM_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'GLM_RDEMO_DETAILS_REGRESSION');
    INSERT INTO GLM_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(200)) attr, 1 coef FROM dual');
    INSERT INTO GLM_RDEMO_SETTINGS_RE (setting_name, setting_value) VALUES
    ('ODMS_ROW_WEIGHT_COLUMN_NAME', 'YRS_RESIDENCE');
END;
/
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'GLM_RDEMO_REGRESSION',
      mining_function     => dbms_data_mining.regression,
      data_table_name     => 'mining_data_build_v',
      case_id_column_name => 'CUST_ID',
      target_column_name  => 'AGE',
      settings_table_name => 'GLM_RDEMO_SETTINGS_RE');
END;
/

-------------------------------------------------------------------------------
--                              MODEL DETAIL
-------------------------------------------------------------------------------

-- Explanation:
-- Display the details of the built model using the R script user defined. 
-- Here R script GLM_RDEMO_DETAIL_REGRESSION will be used to display the model 
-- details.

column attr format a40

SELECT attr, round(coef, 3) as coef FROM DM$VDGLM_RDEMO_REGRESSION 
ORDER BY attr;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------

-- Explanation:
-- Score the model using the R script user defined. Here R script 
-- GLM_RDEMO_SCORE_REGRESSION will be used to do the scoring. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
-- Explanation:
-- Show actual target value and predicted target values.

SELECT CUST_ID, round(PREDICTION(GLM_RDEMO_REGRESSION USING *), 3) as AGE_pred, 
AGE as AGE_act 
FROM mining_data_apply_v WHERE CUST_ID <= 100010 
ORDER BY CUST_ID;

-- PREDICTION_BOUND -----------------------------------------------------------
-- Explanation:
-- Show actual target value, predicted target values, upper bounds, lower 
-- bounds. 

SELECT CUST_ID, AGE, 
       round(PREDICTION(GLM_RDEMO_REGRESSION USING *), 3) as AGE_pred,
       round(PREDICTION_BOUNDS(GLM_RDEMO_REGRESSION USING *).UPPER, 3) as upp, 
       round(PREDICTION_BOUNDS(GLM_RDEMO_REGRESSION USING *).LOWER, 3) as low 
FROM mining_data_apply_v WHERE CUST_ID <= 100010 
ORDER BY CUST_ID;

-- Specify Confidence Level 0.9 -----------------------------------------------
-- Explanation:
-- Show predicted target values, bounds, middle value. 

SELECT CUST_ID, round(AGE_pred, 3) as AGE_pred, 
round((upp - low)/2, 3) as bound, round((low+upp)/2, 3) as pred_mid
FROM (SELECT CUST_ID, PREDICTION(GLM_RDEMO_REGRESSION USING *) AGE_pred,
             PREDICTION_BOUNDS(GLM_RDEMO_REGRESSION, 0.9 USING *).LOWER low,
             PREDICTION_BOUNDS(GLM_RDEMO_REGRESSION, 0.9 USING *).UPPER upp
FROM mining_data_apply_v WHERE CUST_ID <= 100010) 
ORDER BY CUST_ID;

-------------------------------------------------------------------------------
--                        GLM CLASSIFICATION DEMO
-------------------------------------------------------------------------------

-- Explaination:
-- This demo shows how to implement the GLM classification algorithm in Oracle 
-- Data Mining using R glm algorithm.

-- Cleanup old output tables/scripts/models for repeat runs -------------------

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_CL';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

Begin
  sys.rqScriptDrop('GLM_RDEMO_BUILD_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_SCORE_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_DETAILS_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_WEIGHT_CLASSIFICATION', v_silent => TRUE);
End;
/


-- Model Settings -------------------------------------------------------------


Begin
-- Build R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to build the model they want. 
-- For example, here a script named GLM_RDEMO_BUILD_CLASSIFICATION is defined. 
-- This function builds and returns a GLM classification model using R glm 
-- algorithm. User can also choose other R algorithm to implement the GLM 
-- classification algorithm.

  sys.rqScriptCreate('GLM_RDEMO_BUILD_CLASSIFICATION', 
                     'function(dat, form, keep.model) {
   set.seed(1234); 
   mod <- glm(formula = formula(form), data=dat, 
              family=binomial(logit), model = as.logical(keep.model)); 
   mod}');

-- Score R Function -----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to do the scoring using the built
-- model. For example, here a script named GLM_RDEMO_SCORE_CLASSIFICATION is 
-- defined. This function creates and returns an R data.frame containing the 
-- target predictions using type response. User can also define other PREDICTION 
-- functions with different types.

  sys.rqScriptCreate('GLM_RDEMO_SCORE_CLASSIFICATION', 'function(mod, dat) {
   res <- predict(mod, newdata = dat, type="response"); 
   res2=data.frame(1-res, res); names(res2) <- c("0", "1"); res2}');

-- Detail R Function ----------------------------------------------------------
-- Explanation:
-- User can define their own R script function to show the model details they
-- want to display. For example, here a script named 
-- GLM_RDEMO_DETAILS_CLASSIFICATION is defined. This function creates and 
-- returns an R data.frame containing the attribute coefficients of the built 
-- model. User can also display other details.

  sys.rqScriptCreate('GLM_RDEMO_DETAILS_CLASSIFICATION', 'function(object) {
   mod <- object; 
   data.frame(name=names(mod$coefficients), 
   coef=mod$coefficients)}');

-- Model Weight R Function ----------------------------------------------------
-- Explanation:
-- User can define their own R script function to provide the attribute weights
-- of the scoring data. For example, here a script named 
-- GLM_RDEMO_WEIGHT_CLASSIFICATION is defined. This function creates and returns
-- an R data.frame containing the weights of each attribute of the scoring data.
-- Here we simply use the product of the attribute value with the attribute
-- coefficients as the weight of the missing attribute. User can define their 
-- own method to calculate the attribute weight.

  sys.rqScriptCreate('GLM_RDEMO_WEIGHT_CLASSIFICATION', 'function(mod, dat, clas) {

   v <- predict(mod, newdata=dat, type = "response");
   v0 <- data.frame(v, 1-v); names(v0) <- c("0", "1");
   res <- data.frame(lapply(seq_along(dat),
   function(x, dat) {
   if(is.numeric(dat[[x]])) dat[,x] <- as.numeric(0)
   else dat[,x] <- as.factor(NA);
   vv <- predict(mod, newdata = dat, type = "response");
   vv = data.frame(vv, 1-vv); names(vv) <- c("0", "1");
   v0[[clas]] / vv[[clas]]}, dat = dat));
   names(res) <- names(dat);
   res}');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- attribute names and the corresponding coefficients.

-- In this setting, a formula is specified, which will be passed as a parameter 
-- to the model build function to build the model.

End;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------

-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- GLM_RDEMO_BUILD_CLASSIFICATION will be used to create the GLM classification
-- model GLM_RDEMO_CLASSIFICATION using dataset mining_data_build_v.


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_CLASSIFICATION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'GLM_RDEMO_BUILD_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_score_function) := 'GLM_RDEMO_SCORE_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_details_function) := 'GLM_RDEMO_DETAILS_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_weight_function) := 'GLM_RDEMO_WEIGHT_CLASSIFICATION';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT cast(''a'' as varchar2(200)) attr, 1 coef FROM dual';
  v_setlst(dbms_data_mining.ralg_build_parameter) := 'SELECT ''AFFINITY_CARD ~ AGE + EDUCATION + HOUSEHOLD_SIZE + OCCUPATION'' ' ||
  '"form", 0 "keep.model" FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'GLM_RDEMO_CLASSIFICATION',
    mining_function     => dbms_data_mining.classification,
    data_query          => 'SELECT * FROM mining_data_build_v',
    case_id_column_name => 'CUST_ID',
    target_column_name  => 'AFFINITY_CARD',
    set_list            => v_setlst
    );
END;
/

-----------------------------------------------------------------------
-- CREATE_MODEL EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL is useful for application development when model settings
-- are separated into a settings table for convenient updating.
-- This build intentionally replaces the model created by the preceding CREATE_MODEL2 example.

-- Drop settings table if it exists
BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_CL';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_CLASSIFICATION');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE GLM_RDEMO_SETTINGS_CL (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO GLM_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO GLM_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'GLM_RDEMO_BUILD_CLASSIFICATION');
    INSERT INTO GLM_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_score_function, 'GLM_RDEMO_SCORE_CLASSIFICATION');
    INSERT INTO GLM_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'GLM_RDEMO_DETAILS_CLASSIFICATION');
    INSERT INTO GLM_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_weight_function, 'GLM_RDEMO_WEIGHT_CLASSIFICATION');
    INSERT INTO GLM_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT cast(''a'' as varchar2(200)) attr, 1 coef FROM dual');
    INSERT INTO GLM_RDEMO_SETTINGS_CL (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_parameter, 'SELECT ''AFFINITY_CARD ~ AGE + EDUCATION + HOUSEHOLD_SIZE + OCCUPATION'' ' ||
    '"form", 0 "keep.model" FROM dual');
END;
/
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

-------------------------------------------------------------------------------
--                              MODEL DETAIL
-------------------------------------------------------------------------------

-- Display the details of the built model using the R script user defined. 
-- Here R script GLM_RDEMO_DETAIL_CLASSIFICATION will be used to display the 
-- model details.

column attr format a40

SELECT attr, round(coef, 3) as coef FROM DM$VDGLM_RDEMO_CLASSIFICATION 
ORDER BY attr;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------

-- Explanation:
-- Score the model using the R script user defined. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
-- Explanation:
-- Here R script GLM_RDEMO_SCORE_CLASSIFICATION is used to get the PREDICTION 
-- value and the PREDICTION probability. Actual target value and predicted 
-- target values are provided.

SELECT CUST_ID, AFFINITY_CARD as AFFINITY_CARD_act, 
PREDICTION(GLM_RDEMO_CLASSIFICATION USING *) AFFINITY_CARD_pred,
round(PREDICTION_PROBABILITY(GLM_RDEMO_CLASSIFICATION USING *), 3) 
as AFFINITY_CARD_prob 
FROM mining_data_apply_v WHERE CUST_ID <= 100010 
ORDER BY CUST_ID;

-- PREDICTION_SET -------------------------------------------------------------
-- Explanation:
-- Here R script GLM_RDEMO_SCORE_CLASSIFICATION is used to get the 
-- PREDICTION set. Actual target value and predicted target values are provided.

SELECT T.CUST_ID, T.AFFINITY_CARD, S.PREDICTION, 
round(S.probability, 3) as probability 
FROM (SELECT CUST_ID, AFFINITY_CARD, 
PREDICTION_SET(GLM_RDEMO_CLASSIFICATION USING *) pset 
FROM mining_data_apply_v WHERE CUST_ID <= 100010) T, TABLE(T.pset) S
WHERE S.probability > 0 
ORDER BY T.CUST_ID, S.PREDICTION;

-- PREDICTION_DETAILS ---------------------------------------------------------
-- Explanation:
-- The R script GLM_RDEMO_WEIGHT_CLASSIFICATION is used to get the PREDICTION 
-- details. The CUST_ID and PREDICTION details with each attribute weight
-- are provided.

column pred_det format a65;

SELECT CUST_ID, PREDICTION_DETAILS(GLM_RDEMO_CLASSIFICATION, '0' USING *) pred_det
FROM mining_data_apply_v WHERE CUST_ID <= 100010 ORDER BY CUST_ID;

-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_REGRESSION');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_CLASSIFICATION');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_RE';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_CL';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
