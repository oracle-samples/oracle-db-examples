-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 26ai
-- 
--   OML R Extensible - K-Means Algorithm - dmrkmdemo.sql
--   
--   Copyright (c) 2026 Oracle Corporation and/or its affilitiates.
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
BEGIN EXECUTE IMMEDIATE 'DROP VIEW km_build_v';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Create a view for building kmeans model
create view km_build_v as
select cust_id, age, yrs_residence, affinity_card, bulk_pack_diskettes,
flat_panel_monitor, home_theater_package, bookkeeping_application, y_box_games  
from mining_data_build_v;


-----------------------------------------------------------------------
--                            BUILD THE MODEL
-----------------------------------------------------------------------

-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('RKM_SH_CLUS_SAMPLE');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table and R scripts for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE Rkm_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN
sys.rqScriptDrop('RKM_BUILD');
sys.rqScriptDrop('RKM_SCORE');
sys.rqScriptDrop('RKM_WEIGHT');
sys.rqScriptDrop('RKM_DETAILS');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE Rkm_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

------------
-- R scripts
--
-- The R scripts are created by users using sys.rqScriptCreate to define
-- their own approaches in R for building CLUSTERING models and 
-- scoring new data in ODM framework.
--
-- Here is the mapping between the R scripts and ODM functions/PROCs that
-- invoke and use the R scripts. Please refer to user guide for details.
--------------------------------------------------------------------------
-- ralg_build_function           -------   CREATE_MODEL 
-- ralg_score_function           -------   CLUSTER_ID, CLUSTER_PROBABILITY
--                                         CLUSTER_SET, CLUSTER_DISTANCE
-- ralg_weight_function          -------   CLUSTER_DETAILS
-- ralg_details_function         -------   CREATE_MODEL(to generate model view)
-- ralg_details_format           -------   CREATE_MODEL(to generate model view)

BEGIN
  INSERT INTO Rkm_sh_sample_settings VALUES
  ('ALGO_EXTENSIBLE_LANG', 'R');
 
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
-- We calulate the new probability without accounting for an attribute, and
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
    
  INSERT INTO Rkm_sh_sample_settings VALUES
  (dbms_data_mining.ralg_build_function, 'RKM_BUILD');
  INSERT INTO Rkm_sh_sample_settings VALUES
  (dbms_data_mining.ralg_score_function, 'RKM_SCORE');
  INSERT INTO Rkm_sh_sample_settings VALUES
  (dbms_data_mining.ralg_weight_function, 'RKM_WEIGHT');
  INSERT INTO Rkm_sh_sample_settings VALUES
  (dbms_data_mining.ralg_details_function, 'RKM_DETAILS');
  INSERT INTO Rkm_sh_sample_settings VALUES
  (dbms_data_mining.ralg_details_format, 
  'select 1 clus, 1 withinss, 1 clussize from dual');
END;
/

---------------------
-- CREATE A NEW MODEL
--
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
--
column setting_name format a30
column setting_value format a30
select setting_name, setting_value from Rkm_sh_sample_settings
order by setting_name;
      
-------------------------
-- DISPLAY MODEL METADATA
--
column model_name format a20
column mining_function format a20
column algorithm format a20
select model_name, mining_function, algorithm from user_mining_models
where model_name = 'RKM_SH_CLUS_SAMPLE';

------------------------
-- DISPLAY MODEL DETAILS
--
column partition_name format a20
select * from DM$VDRKM_SH_CLUS_SAMPLE order by clus;


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
      where cust_id <= 100015
      ORDER BY cust_id);
      
-- List the probabilities for each cluster for 15 new customers 
-- using CLUSTER_SET      
--
select T.cust_id, S.cluster_id, S.probability
from (select cust_id, CLUSTER_SET(RKM_SH_CLUS_SAMPLE USING *) pset 
      FROM mining_data_apply_v) T, TABLE(T.pset) S
where T.cust_id <= 100015
order by T.cust_id, S.cluster_id;

-- List the cluster and distance to its centroid for 15 new customers 
--
select cust_id, CLUSTER_ID(RKM_SH_CLUS_SAMPLE USING *) clus, 
CLUSTER_DISTANCE(RKM_SH_CLUS_SAMPLE USING *) dis
from mining_data_apply_v
where cust_id <= 100015 order by cust_id;

-- List the 5 most important attributes for each row for 15 new customers
--
column clus_det format a60
SELECT cust_id, CLUSTER_DETAILS(RKM_SH_CLUS_SAMPLE USING *) clus_det
FROM mining_data_apply_v where cust_id <= 100015 order by cust_id;

-- List the 10 rows which are most anomalous as measured by their
-- distance from the cluster centroids.  A row which is far from
-- all cluster centroids may be anomalous.
--
select cust_id, dist
from(
select cust_id, CLUSTER_DISTANCE(RKM_SH_CLUS_SAMPLE USING *) dist,
       rank() over (order by CLUSTER_DISTANCE(RKM_SH_CLUS_SAMPLE USING *) desc) rnk 
from mining_data_apply_v)
where rnk <=10
order by rnk;



-----------------------------------------------------------------------
--                      BUILD A MODEL USING SAMPLING
-----------------------------------------------------------------------
-- This example illustrates building a kmeans model by sampling the
-- training data. We use the same settings table in the above example 
-- with additional sampling settings.

-- Enable sampling and specify sample size in setting table
INSERT INTO Rkm_sh_sample_settings VALUES
('ODMS_SAMPLING', 'ODMS_SAMPLING_ENABLE');
INSERT INTO Rkm_sh_sample_settings VALUES 
('ODMS_SAMPLE_SIZE', 1000);

-- Cleanup old model with same name for repeat runs
BEGIN DBMS_DATA_MINING.DROP_MODEL('RKM_SH_CLUS_SAMPLE_S');
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-----------------------------------
-- CREATE A NEW MODEL WITH SAMPLING
--
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
--
select setting_name, setting_value from Rkm_sh_sample_settings
order by setting_name;
      
-------------------------
-- DISPLAY MODEL METADATA
--
select model_name, mining_function, algorithm from user_mining_models
where model_name = 'RKM_SH_CLUS_SAMPLE_S';

------------------------
-- DISPLAY MODEL DETAILS
--
column partition_name format a20
select * from DM$VDRKM_SH_CLUS_SAMPLE_S order by clus;

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
      where cust_id <= 100015
      ORDER BY cust_id);
