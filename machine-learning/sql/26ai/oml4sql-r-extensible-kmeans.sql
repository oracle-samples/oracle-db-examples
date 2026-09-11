-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
--   OML R Extensible - K-Means Algorithm - dmrkmdemo.sql  
--   Copyright (c) 2026 Oracle Corporation and/or its affiliates.
--
--   The Universal Permissive License (UPL), Version 1.0
--   https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------

SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

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

BEGIN
  EXECUTE IMMEDIATE 'DROP VIEW km_build_v';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- Create a view for building kmeans model
create view km_build_v as
SELECT cust_id, age, yrs_residence, affinity_card, bulk_pack_diskettes,
flat_panel_monitor, home_theater_package, bookkeeping_application, y_box_games  
FROM mining_data_build_v;


-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------


-------------------
-- SPECIFY SETTINGS
-------------------


BEGIN
sys.rqScriptDrop('RKM_BUILD');
sys.rqScriptDrop('RKM_SCORE');
sys.rqScriptDrop('RKM_WEIGHT');
sys.rqScriptDrop('RKM_DETAILS');
  EXCEPTION WHEN OTHERS THEN NULL; END;
/

------------
-- R scripts
------------

-- The R scripts are created by users using sys.rqScriptCreate to define
-- their own approaches in R for building CLUSTERING models and 
-- scoring new data in OML4SQL framework.
--

-- Here is the mapping between the R scripts and OML4SQL functions/PROCs that
-- invoke and use the R scripts. Please refer to user guide for details.
--------------------------------------------------------------------------

-- ralg_build_function           -------   CREATE_MODEL 
-- ralg_score_function           -------   CLUSTER_ID, CLUSTER_PROBABILITY
--                                         CLUSTER_SET, CLUSTER_DISTANCE
-- ralg_weight_function          -------   CLUSTER_DETAILS
-- ralg_details_function         -------   CREATE_MODEL(to generate model view)
-- ralg_details_format           -------   CREATE_MODEL(to generate model view)

BEGIN
 
-- Our BUILD script here uses R's kmeans function to build a kmeans model.
-- We centralize and normalize the training data before the model build.
-- Predefined attribute dm$nclus must be set on the generated R model to
-- indicate the number of clusters produced by the clustering model fit.
  sys.rqScriptCreate('RKM_BUILD', 
    'function(dat) {dat.scaled <- scale(dat)
     set.seed(6543); mod <- list()
     fit <- kmeans(dat.scaled, centers = 3L)
     mod[[1L]] <- fit
     mod[[2L]] <- attr(dat.scaled, "scaled:center")
     mod[[3L]] <- attr(dat.scaled, "scaled:scale")
     attr(mod, "dm$nclus") <- nrow(fit$centers)
     mod}');

-- Our SCORE script here calculates the probabilities and distances to
-- each cluster of the new data. It returns a data.frame combining columns
-- of cluster probabilities and columns of cluster distances.
-- We calculate the probability based on the normal distribution with distance.
-- The distance here is referred to Euclidean distance.   
  sys.rqScriptCreate('RKM_SCORE',
    'function(x, dat){
     mod <- x[[1L]]; ce <- x[[2L]]; sc <- x[[3L]]
     newdata = scale(dat, center = ce, scale = sc)
     centers <- mod$centers
     ss <- sapply(as.data.frame(t(centers)), 
     function(v) rowSums(scale(newdata, center=v, scale=FALSE)^2))
     if (!is.matrix(ss)) ss <- matrix(ss, ncol=length(ss))
     disp <- -1 / (2* mod$tot.withinss/length(mod$cluster))
     distr <- exp(disp*ss)
     prob <- distr / rowSums(distr)
     as.data.frame(cbind(prob, sqrt(ss)))}');

-- Our WEIGHT script here calculates the attribute importance of new data for
-- the specified cluster. It returns a data.frame with each column representing
-- the weights of the corresponding attribute.
-- We calculate the new probability without accounting for an attribute, and
-- the attribute importance is the difference between the original probability
-- by SCORING and the new probability.
  sys.rqScriptCreate('RKM_WEIGHT', 
     'function(x, dat, clus) {
      clus <- as.numeric(clus)
      mod <- x[[1L]]; ce <- x[[2L]]; sc <- x[[3L]]
      newdata <- scale(dat, center = ce, scale = sc)
      centers <- mod$centers
      ss <- sapply(as.data.frame(t(centers)),
      function(v) rowSums(scale(newdata, center=v, scale=FALSE)^2))
      if (!is.matrix(ss)) ss <- matrix(ss, ncol=length(ss))
      disp <- -1 / (2* mod$tot.withinss/length(mod$cluster))
      distr <- exp(disp*ss)
      prob0 <- distr[, clus] / rowSums(distr)
      for (iattr in 1:ncol(newdata)) {
      newd <- newdata[, -iattr]
      if(!is.matrix(newd)) newd <- matrix(newd, ncol=length(newd))
      ss <- sapply(as.data.frame(t(centers[, -iattr])),
      function(v) rowSums(scale(newd, center=v, scale=FALSE)^2))
      if (!is.matrix(ss)) ss <- matrix(ss, ncol=length(ss))
      distr <- exp(disp*ss)
      prob <- distr[, clus] / rowSums(distr)
      w <- prob0-prob
      if (iattr == 1) res <- as.data.frame(w)
      else res <- cbind(res, w)
      }
      colnames(res) <- colnames(mod$centers)
      res}');

-- The DETAILS script, along with the FORMAT script below will be 
-- invoked during CREATE_MODEL. A model view will be generated with 
-- the output of the DETAILS script.
-- Our DETAILS script returns a data.frame containing the sum of squares 
-- within clusters and the cluster size of the model.        
  sys.rqScriptCreate('RKM_DETAILS',
     'function(x) {
      mod <- x[[1L]]
      data.frame(clus = seq(length(mod$size)), withinss=mod$withinss, 
      clussize=mod$size)}');
    
END;
/

-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RKM_SH_CLUS_SAMPLE');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'RKM_BUILD';
  v_setlst(dbms_data_mining.ralg_score_function) := 'RKM_SCORE';
  v_setlst(dbms_data_mining.ralg_weight_function) := 'RKM_WEIGHT';
  v_setlst(dbms_data_mining.ralg_details_function) := 'RKM_DETAILS';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT 1 clus, 1 withinss, 1 clussize FROM dual';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'RKM_SH_CLUS_SAMPLE',
    mining_function     => dbms_data_mining.clustering,
    data_query          => 'SELECT * FROM KM_BUILD_V',
    case_id_column_name => 'CUST_ID',
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
  EXECUTE IMMEDIATE 'DROP TABLE Rkm_sh_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RKM_SH_CLUS_SAMPLE');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE Rkm_sh_sample_settings (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'RKM_BUILD');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_score_function, 'RKM_SCORE');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_weight_function, 'RKM_WEIGHT');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'RKM_DETAILS');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT 1 clus, 1 withinss, 1 clussize FROM dual');
END;
/
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'RKM_SH_CLUS_SAMPLE',
      mining_function     => dbms_data_mining.clustering,
      data_table_name     => 'KM_BUILD_V',
      case_id_column_name => 'CUST_ID',
      settings_table_name => 'Rkm_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
-------------------------

column setting_name format a30
column setting_value format a30

SELECT setting_name, setting_value FROM Rkm_sh_sample_settings
ORDER BY setting_name;
      
-------------------------
-- DISPLAY MODEL METADATA
-------------------------

column model_name format a20
column mining_function format a20
column algorithm format a20

SELECT model_name, mining_function, algorithm FROM user_mining_models
WHERE model_name = 'RKM_SH_CLUS_SAMPLE';

------------------------
-- DISPLAY MODEL DETAILS
------------------------

column partition_name format a20

SELECT * FROM DM$VDRKM_SH_CLUS_SAMPLE ORDER BY clus;


-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------

-- For a descriptive mining function like Clustering, "Scoring" involves
-- providing the probability values, distances for each cluster.

-- List the count per cluster into which the customers in this
-- given dataset have been grouped.
--

SELECT CLUSTER_ID(RKM_SH_CLUS_SAMPLE USING *) AS clus, COUNT(*) AS cnt
FROM mining_data_apply_v
GROUP BY CLUSTER_ID(RKM_SH_CLUS_SAMPLE USING *)
ORDER BY clus;

-- List the cluster and the corresponding probabilities for 15 new customers
--

SELECT cust_id, clus, prob, prob_1, prob_2, prob_3, prob_1+prob_2+prob_3 prob_tot
FROM (SELECT cust_id, CLUSTER_ID(RKM_SH_CLUS_SAMPLE USING *) clus,
             CLUSTER_PROBABILITY(RKM_SH_CLUS_SAMPLE USING *) prob,
             CLUSTER_PROBABILITY(RKM_SH_CLUS_SAMPLE, 1 USING *) prob_1,
             CLUSTER_PROBABILITY(RKM_SH_CLUS_SAMPLE, 2 USING *) prob_2,
             CLUSTER_PROBABILITY(RKM_SH_CLUS_SAMPLE, 3 USING *) prob_3            
FROM mining_data_apply_v
WHERE cust_id <= 100015
ORDER BY cust_id);
      
-- List the probabilities for each cluster for 15 new customers 
-- using CLUSTER_SET      
--

SELECT T.cust_id, S.cluster_id, S.probability
FROM (SELECT cust_id, CLUSTER_SET(RKM_SH_CLUS_SAMPLE USING *) pset 
FROM mining_data_apply_v) T, TABLE(T.pset) S
WHERE T.cust_id <= 100015
ORDER BY T.cust_id, S.cluster_id;

-- List the cluster and distance to its centroid for 15 new customers 
--

SELECT cust_id, CLUSTER_ID(RKM_SH_CLUS_SAMPLE USING *) clus, 
CLUSTER_DISTANCE(RKM_SH_CLUS_SAMPLE USING *) dis
FROM mining_data_apply_v
WHERE cust_id <= 100015 ORDER BY cust_id;

-- List the 5 most important attributes for each row for 15 new customers
--

column clus_det format a60

SELECT cust_id, CLUSTER_DETAILS(RKM_SH_CLUS_SAMPLE USING *) clus_det
FROM mining_data_apply_v WHERE cust_id <= 100015 ORDER BY cust_id;

-- List the 10 rows which are most anomalous as measured by their
-- distance from the cluster centroids. A row that is far from
-- all cluster centroids may be anomalous.
--

SELECT cust_id, dist
FROM(
SELECT cust_id, CLUSTER_DISTANCE(RKM_SH_CLUS_SAMPLE USING *) dist,
       rank() OVER (ORDER BY CLUSTER_DISTANCE(RKM_SH_CLUS_SAMPLE USING *) DESC) rnk 
FROM mining_data_apply_v)
WHERE rnk <=10
ORDER BY rnk;


-----------------------------------------------------------------------
--                      BUILD A MODEL USING SAMPLING
-----------------------------------------------------------------------

-- This example illustrates building a kmeans model by sampling the
-- training data. We use the same settings table in the above example 
-- with additional sampling settings.

-- Enable sampling and specify sample size in setting table

-----------------------------------
-- CREATE A NEW MODEL WITH SAMPLING
-----------------------------------


-----------------------------------------------------------------------
-- CREATE_MODEL2 EXAMPLE
-----------------------------------------------------------------------

-- CREATE_MODEL2 is useful when you want to provide a data query
-- and an explicit settings list instead of maintaining settings in a table.

BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RKM_SH_CLUS_SAMPLE_S');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE
  v_setlst DBMS_DATA_MINING.SETTING_LIST;
BEGIN
  v_setlst('ALGO_EXTENSIBLE_LANG') := 'R';
  v_setlst(dbms_data_mining.ralg_build_function) := 'RKM_BUILD';
  v_setlst(dbms_data_mining.ralg_score_function) := 'RKM_SCORE';
  v_setlst(dbms_data_mining.ralg_weight_function) := 'RKM_WEIGHT';
  v_setlst(dbms_data_mining.ralg_details_function) := 'RKM_DETAILS';
  v_setlst(dbms_data_mining.ralg_details_format) := 'SELECT 1 clus, 1 withinss, 1 clussize FROM dual';
  v_setlst('ODMS_SAMPLING') := 'ODMS_SAMPLING_ENABLE';
  v_setlst('ODMS_SAMPLE_SIZE') := '1000';
  DBMS_DATA_MINING.CREATE_MODEL2(
    model_name          => 'RKM_SH_CLUS_SAMPLE_S',
    mining_function     => dbms_data_mining.clustering,
    data_query          => 'SELECT * FROM KM_BUILD_V',
    case_id_column_name => 'CUST_ID',
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
  EXECUTE IMMEDIATE 'DROP TABLE Rkm_sh_sample_settings';
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/
BEGIN
  DBMS_DATA_MINING.DROP_MODEL('RKM_SH_CLUS_SAMPLE_S');
  EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'CREATE TABLE Rkm_sh_sample_settings (setting_name VARCHAR2(30), setting_value VARCHAR2(4000))';
END;
/

BEGIN
INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    ('ALGO_EXTENSIBLE_LANG', 'R');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_build_function, 'RKM_BUILD');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_score_function, 'RKM_SCORE');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_weight_function, 'RKM_WEIGHT');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_function, 'RKM_DETAILS');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    (dbms_data_mining.ralg_details_format, 'SELECT 1 clus, 1 withinss, 1 clussize FROM dual');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    ('ODMS_SAMPLING', 'ODMS_SAMPLING_ENABLE');
    INSERT INTO Rkm_sh_sample_settings (setting_name, setting_value) VALUES
    ('ODMS_SAMPLE_SIZE', 1000);
END;
/
BEGIN
  DBMS_DATA_MINING.CREATE_MODEL(
      model_name          => 'RKM_SH_CLUS_SAMPLE_S',
      mining_function     => dbms_data_mining.clustering,
      data_table_name     => 'KM_BUILD_V',
      case_id_column_name => 'CUST_ID',
      settings_table_name => 'Rkm_sh_sample_settings');
END;
/

-------------------------
-- DISPLAY MODEL SETTINGS
-------------------------

SELECT setting_name, setting_value FROM Rkm_sh_sample_settings
ORDER BY setting_name;
      
-------------------------
-- DISPLAY MODEL METADATA
-------------------------

SELECT model_name, mining_function, algorithm FROM user_mining_models
WHERE model_name = 'RKM_SH_CLUS_SAMPLE_S';

------------------------
-- DISPLAY MODEL DETAILS
------------------------

column partition_name format a20

SELECT * FROM DM$VDRKM_SH_CLUS_SAMPLE_S ORDER BY clus;

-----------------------------------------------------------------------
--                               APPLY THE MODEL
-----------------------------------------------------------------------

-- List the cluster and the corresponding probabilities for 15 new customers
--

SELECT cust_id, clus, prob, prob_1, prob_2, prob_3, prob_1+prob_2+prob_3 prob_tot
FROM (SELECT cust_id, CLUSTER_ID(RKM_SH_CLUS_SAMPLE_S USING *) clus,
             CLUSTER_PROBABILITY(RKM_SH_CLUS_SAMPLE_S USING *) prob,
             CLUSTER_PROBABILITY(RKM_SH_CLUS_SAMPLE_S, 1 USING *) prob_1,
             CLUSTER_PROBABILITY(RKM_SH_CLUS_SAMPLE_S, 2 USING *) prob_2,
             CLUSTER_PROBABILITY(RKM_SH_CLUS_SAMPLE_S, 3 USING *) prob_3            
FROM mining_data_apply_v
WHERE cust_id <= 100015
ORDER BY cust_id);

-----------------------------------------------------------------------
-- OPTIONAL CLEANUP (DISABLED)
-----------------------------------------------------------------------
-- Uncomment this section to remove models and named tables/views created
-- by this script. Shared MINING_* views created by dmsh.sql are intentionally not included.

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('RKM_SH_CLUS_SAMPLE');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   DBMS_DATA_MINING.DROP_MODEL('RKM_SH_CLUS_SAMPLE_S');
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP VIEW KM_BUILD_V';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /

-- BEGIN
--   EXECUTE IMMEDIATE 'DROP TABLE RKM_SH_SAMPLE_SETTINGS';
--   EXCEPTION WHEN OTHERS THEN NULL;
-- END;
-- /
