-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 20c
-- 
--   OML R Extensible - Generalized Linear Model Algorithm - dmrglmdemo.sql
--   
--   Copyright (c) 2020 Oracle and/or its affilitiates. 
-----------------------------------------------------------------------
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
BEGIN EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_RE';  
EXCEPTION WHEN OTHERS THEN NULL; END;
/

Begin
  sys.rqScriptDrop('GLM_RDEMO_BUILD_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_SCORE_REGRESSION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_DETAILS_REGRESSION', v_silent => TRUE);
End;
/

BEGIN DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_REGRESSION');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Model Settings -------------------------------------------------------------
CREATE TABLE GLM_RDEMO_SETTINGS_RE (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

BEGIN
 INSERT INTO GLM_RDEMO_SETTINGS_RE VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
END;
/

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
-- predictions with se.fit on. User can also define other prediction functions
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

  INSERT INTO GLM_RDEMO_SETTINGS_RE 
    VALUES(dbms_data_mining.ralg_build_function, 'GLM_RDEMO_BUILD_REGRESSION');
  INSERT INTO GLM_RDEMO_SETTINGS_RE 
    VALUES(dbms_data_mining.ralg_score_function, 'GLM_RDEMO_SCORE_REGRESSION');
  INSERT INTO GLM_RDEMO_SETTINGS_RE 
    VALUES(dbms_data_mining.ralg_details_function, 'GLM_RDEMO_DETAILS_REGRESSION');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- attribute names and the corresponding coefficients.

  INSERT INTO GLM_RDEMO_SETTINGS_RE 
    VALUES(dbms_data_mining.ralg_details_format, 
    'select cast(''a'' as varchar2(200)) attr, 1 coef from dual');

-- Column YRS_RESIDENCE has row weights.

  INSERT INTO GLM_RDEMO_SETTINGS_RE 
    VALUES('ODMS_ROW_WEIGHT_COLUMN_NAME', 'YRS_RESIDENCE');
End;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------
-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- GLM_RDEMO_BUILD_REGRESSION will be used to create the GLM regression model 
-- GLM_RDEMO_REGRESSION using dataset mining_data_build_v.

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
select attr, round(coef, 3) as coef from DM$VDGLM_RDEMO_REGRESSION 
order by attr;

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
FROM mining_data_apply_v where CUST_ID <= 100010 
order by CUST_ID;

-- PREDICTION_BOUND -----------------------------------------------------------
-- Explanation:
-- Show actual target value, predicted target values, upper bounds, lower 
-- bounds. 

SELECT CUST_ID, AGE, 
       round(PREDICTION(GLM_RDEMO_REGRESSION USING *), 3) as AGE_pred,
       round(PREDICTION_BOUNDS(GLM_RDEMO_REGRESSION USING *).UPPER, 3) as upp, 
       round(PREDICTION_BOUNDS(GLM_RDEMO_REGRESSION USING *).LOWER, 3) as low 
FROM mining_data_apply_v where CUST_ID <= 100010 
order by CUST_ID;

-- Specify Confidence Level 0.9 -----------------------------------------------
-- Explanation:
-- Show predicted target values, bounds, middle value. 

select CUST_ID, round(AGE_pred, 3) as AGE_pred, 
round((upp - low)/2, 3) as bound, round((low+upp)/2, 3) as pred_mid
from (select CUST_ID, PREDICTION(GLM_RDEMO_REGRESSION USING *) AGE_pred,
             PREDICTION_BOUNDS(GLM_RDEMO_REGRESSION, 0.9 USING *).LOWER low,
             PREDICTION_BOUNDS(GLM_RDEMO_REGRESSION, 0.9 USING *).UPPER upp
FROM mining_data_apply_v where CUST_ID <= 100010) 
order by CUST_ID;

-------------------------------------------------------------------------------
--                        GLM CLASSIFICATION DEMO
-------------------------------------------------------------------------------
-- Explaination:
-- This demo shows how to implement the GLM classification algorithm in Oracle 
-- Data Mining using R glm algorithm.

-- Cleanup old output tables/scripts/models for repeat runs -------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE GLM_RDEMO_SETTINGS_CL';  
EXCEPTION WHEN OTHERS THEN NULL; END;
/

Begin
  sys.rqScriptDrop('GLM_RDEMO_BUILD_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_SCORE_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_DETAILS_CLASSIFICATION', v_silent => TRUE);
  sys.rqScriptDrop('GLM_RDEMO_WEIGHT_CLASSIFICATION', v_silent => TRUE);
End;
/

BEGIN DBMS_DATA_MINING.DROP_MODEL('GLM_RDEMO_CLASSIFICATION');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Model Settings -------------------------------------------------------------
CREATE TABLE GLM_RDEMO_SETTINGS_CL (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

BEGIN
 INSERT INTO GLM_RDEMO_SETTINGS_CL VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
END;
/

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
-- target predictions using type response. User can also define other prediction 
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

  INSERT INTO GLM_RDEMO_SETTINGS_CL  
    VALUES(dbms_data_mining.ralg_build_function, 'GLM_RDEMO_BUILD_CLASSIFICATION');
  INSERT INTO GLM_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_score_function, 'GLM_RDEMO_SCORE_CLASSIFICATION');
  INSERT INTO GLM_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_details_function, 'GLM_RDEMO_DETAILS_CLASSIFICATION');
  INSERT INTO GLM_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_weight_function, 'GLM_RDEMO_WEIGHT_CLASSIFICATION');

-- Once this setting is specified, a model view will be created. This model
-- view will be generated to display the model details, which contains the 
-- attribute names and the corresponding coefficients.

  INSERT INTO GLM_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_details_format, 
    'select cast(''a'' as varchar2(200)) attr, 1 coef from dual');

-- In this setting, a formula is specified,  which will be passed as a parameter 
-- to the model build function to build the model.

  INSERT INTO GLM_RDEMO_SETTINGS_CL 
    VALUES(dbms_data_mining.ralg_build_parameter, 
    'select ''AFFINITY_CARD ~ AGE + EDUCATION + HOUSEHOLD_SIZE + OCCUPATION'' ' ||
    '"form", 0 "keep.model" from dual');
End;
/

-------------------------------------------------------------------------------
--                              MODEL BUILD
-------------------------------------------------------------------------------
-- Explanation:
-- Build the model using the R script user defined. Here R script 
-- GLM_RDEMO_BUILD_CLASSIFICATION will be used to create the GLM classification
-- model GLM_RDEMO_CLASSIFICATION using dataset mining_data_build_v.

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
select attr, round(coef, 3) as coef from DM$VDGLM_RDEMO_CLASSIFICATION 
order by attr;

-------------------------------------------------------------------------------
--                              MODEL SCORE
-------------------------------------------------------------------------------
-- Explanation:
-- Score the model using the R script user defined. 

-- PREDICTION/PREDICTION_PROBABILITY ------------------------------------------
-- Explanation:
-- Here R script GLM_RDEMO_SCORE_CLASSIFICATION is used to get the prediction 
-- value and the prediction probability. Actual target value and predicted 
-- target values are provided.

SELECT CUST_ID, AFFINITY_CARD as AFFINITY_CARD_act, 
PREDICTION(GLM_RDEMO_CLASSIFICATION USING *) AFFINITY_CARD_pred,
round(PREDICTION_PROBABILITY(GLM_RDEMO_CLASSIFICATION USING *), 3) 
as AFFINITY_CARD_prob 
FROM mining_data_apply_v where CUST_ID <= 100010 
order by CUST_ID;

-- PREDICTION_SET -------------------------------------------------------------
-- Explanation:
-- Here R script GLM_RDEMO_SCORE_CLASSIFICATION is used to get the 
-- prediction set. Actual target value and predicted target values are provided.

select T.CUST_ID, T.AFFINITY_CARD, S.prediction, 
round(S.probability, 3) as probability 
from (select CUST_ID, AFFINITY_CARD, 
PREDICTION_SET(GLM_RDEMO_CLASSIFICATION USING *) pset 
from mining_data_apply_v where CUST_ID <= 100010) T, TABLE(T.pset) S
where S.probability > 0 
order by T.CUST_ID, S.prediction;

-- PREDICTION_DETAILS ---------------------------------------------------------
-- Explanation:
-- The R script GLM_RDEMO_WEIGHT_CLASSIFICATION is used to get the prediction 
-- details. The CUST_ID and the prediction details with the weight of each 
-- attribute are provided.

column pred_det format a65;
SELECT CUST_ID, PREDICTION_DETAILS(GLM_RDEMO_CLASSIFICATION, '0' USING *) pred_det
FROM mining_data_apply_v where CUST_ID <= 100010 order by CUST_ID;
