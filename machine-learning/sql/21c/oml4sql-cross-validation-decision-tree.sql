-----------------------------------------------------------------------
--   Oracle Machine Learning for SQL (OML4SQL) 21c
-- 
--   Cross-Validation - Decision Tree Algorithm - dmdtxvlddemo.sql
--   
--   Copyright (c) 2021 Oracle Corporation and/or its affilitiates.
--
--  The Universal Permissive License (UPL), Version 1.0
--
--  https://oss.oracle.com/licenses/upl/
-----------------------------------------------------------------------
SET SERVEROUTPUT ON
SET ECHO OFF
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
SET long 2000000000

-----------------------------------------------------------------------
--                            SAMPLE PROBLEM
-----------------------------------------------------------------------
-- Given demographic data about a set of customers, compute the accuracy
-- of predictions for customer response to an affinity card program
-- using a classifier based on Decision Trees algorithm.
--
-- This demo should be viewed as an extension of the scenario 
-- described in dmdtdemo.sql. We perform 10 fold cross-validation
-- using the training data set alone.

-------------------
-- SPECIFY SETTINGS
--
-- Cleanup old settings table objects for repeat runs
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dt_sh_sample_settings';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
 
--------------------------
-- CREATE A SETTINGS TABLE
--
-- The default classification algorithm is Naive Bayes. In order to override
-- this, create and populate a settings table to be used as input for
-- CREATE_MODEL.
-- 
CREATE TABLE dt_sh_sample_settings (
  setting_name  VARCHAR2(30),
  setting_value VARCHAR2(4000));

DECLARE
 nfolds         NUMBER;
 maxbucket      NUMBER;       -- max buckets for ORA_HASH()
 iter           NUMBER;       -- loop itarator
 tgtname        VARCHAR2(30); -- target column name
 tgtval         NUMBER;       -- class value (same type as target column) 
 case_id        VARCHAR2(30); -- case_id column name
 tabname        VARCHAR2(30); -- training data
 tabname_p      VARCHAR2(30); -- "partitioned" training data
 model_name     VARCHAR2(30); -- model_name
 sqltxt         VARCHAR2(32767);
 type dmdtcurtyp IS REF CURSOR;
 tgtcur         dmdtcurtyp;
BEGIN       
 nfolds := 10;               -- number of folds (typically 10 fold)
 maxbucket := nfolds-1;      -- max buckets for ORA_HASH(); max of 9 means
                             -- 10 buckets in all 0..9

 model_name := 'DT_SH_Clas_Xvld_tmp';
 tgtname := 'affinity_card';

 --Training data, can be parametrized for general usage
 tabname := 'mining_data_build_v';
 case_id := 'cust_id';

 -- "partitioned" table
 tabname_p := tabname || '_P';

 -- Populate settings table
 INSERT INTO dt_sh_sample_settings VALUES
   (dbms_data_mining.algo_name, dbms_data_mining.algo_decision_tree);

 -- Examples of other possible settings are:
 --(dbms_data_mining.tree_impurity_metric, 'TREE_IMPURITY_ENTROPY')
 --(dbms_data_mining.tree_term_max_depth, 5)
 --(dbms_data_mining.tree_term_minrec_split, 5)
 --(dbms_data_mining.tree_term_minpct_split, 2)
 --(dbms_data_mining.tree_term_minrec_node, 5)
 --(dbms_data_mining.tree_term_minpct_node, 0.05)
 BEGIN EXECUTE IMMEDIATE 'DROP TABLE dmdtxvld_c';
 EXCEPTION WHEN OTHERS THEN NULL; END;

 -- The column type of the actual and predicted should be the same as the 
 -- target column, in this case it happens to be NUMBER
 EXECUTE IMMEDIATE
 'CREATE TABLE dmdtxvld_c (' ||
   'iter NUMBER, actual NUMBER(10), predicted NUMBER(10), count NUMBER)';

 -- Create "partitioned" table. A new table is created which tags the rows
 -- with a partition number using column 'pn'
 --
 -- Drop if already exists
 BEGIN EXECUTE IMMEDIATE 'DROP TABLE '|| tabname_p;
 EXCEPTION WHEN OTHERS THEN NULL; END;

 -- Instances of each class are partitioned nfolds ways
 sqltxt := 'CREATE TABLE ' || tabname_p || ' AS ';

 -- Open tgtcur using tgtname,tabname;
 OPEN tgtcur FOR 'SELECT DISTINCT(' || tgtname || ') FROM '|| tabname;

 -- Form SQL statement with as many UNION ALL's as distinct target values
 FETCH tgtcur INTO tgtval;
 sqltxt := sqltxt ||
 'SELECT t1.*, MOD(ROWNUM,' || nfolds ||') pn ' ||
   'FROM (SELECT t.*, ORA_HASH(rownum) randrow ' ||
           'FROM ' || tabname || ' t ' ||
          'WHERE ' || tgtname || ' = '''|| tgtval ||''' ORDER BY randrow) t1 ';
 LOOP 
   FETCH tgtcur INTO tgtval;
   EXIT WHEN tgtcur%NOTFOUND;

   sqltxt := sqltxt || 
   'UNION ALL ' ||
   'SELECT t1.*, MOD(ROWNUM,' || nfolds || ') pn ' ||
     'FROM (SELECT t.*, ORA_HASH(rownum) randrow ' ||
             'FROM ' || tabname || ' t ' ||
            'WHERE ' || tgtname || ' = '''|| tgtval||''' ORDER BY randrow) t1 ';
 END LOOP;
 CLOSE tgtcur;

 -- execute the statement
 EXECUTE IMMEDIATE sqltxt;

 -- Iterate nfolds times. Each time we use (nfolds-1)*R/nfolds rows for build
 -- and the remaining R/nfolds rows for testing where R is the number of
 -- training rows (instances)
 --
 FOR iter IN 0..(nfolds-1)
 LOOP

  -- Create the build view
  -- All rows except those in current partition
  EXECUTE IMMEDIATE
  'CREATE OR REPLACE VIEW xvld_tmp_bld_v AS ' ||
  'SELECT * FROM ' || tabname_p || ' WHERE pn != '|| iter;

  -- We will test using rows in current partition
  EXECUTE IMMEDIATE
  'CREATE OR REPLACE VIEW xvld_tmp_tst_v AS ' ||
  'SELECT * FROM ' || tabname_p || ' WHERE pn = '|| iter;

  -- Build a model with this subset of data
  BEGIN
    -- Cleanup old model with same name for repeat runs
    BEGIN DBMS_DATA_MINING.DROP_MODEL(model_name);
    EXCEPTION WHEN OTHERS THEN NULL; END;

    -- Build a DT model
    BEGIN
      DBMS_DATA_MINING.CREATE_MODEL(
        model_name          => model_name,
        mining_function     => dbms_data_mining.classification,
        data_table_name     => 'xvld_tmp_bld_v',
        case_id_column_name => case_id,
        target_column_name  => tgtname,
        settings_table_name => 'dt_sh_sample_settings');
    END;
  
    -- Apply the model, and compute confusion matrix
    -- Confusion matrix is saved away in dmdtxvld_c table tagged by 
    -- iteration number iter
    EXECUTE IMMEDIATE 
    'INSERT INTO dmdtxvld_c ' ||
    'SELECT ' || iter || ',' || tgtname || ' AS actual_target_value,' ||
           'PREDICTION('|| model_name || ' USING *) ' ||
             'AS predicted_target_value,' ||
           'COUNT(*) AS value ' ||
      'FROM xvld_tmp_tst_v ' ||
    'GROUP BY ' || tgtname || ', PREDICTION('|| model_name|| ' USING *) ' ||
    'ORDER BY 1,2';
  END;
 END LOOP;

 -- Drop the model and partitioned table 
 -- remaining from the last iteration
 BEGIN DBMS_DATA_MINING.DROP_MODEL(model_name);
 EXCEPTION WHEN OTHERS THEN NULL; END;

 BEGIN EXECUTE IMMEDIATE 'DROP TABLE '|| TABNAME_P;
 EXCEPTION WHEN OTHERS THEN NULL; END;

 BEGIN EXECUTE IMMEDIATE 'DROP VIEW XVLD_TMP_BLD_V';
 EXCEPTION WHEN OTHERS THEN NULL; END;

 BEGIN EXECUTE IMMEDIATE 'DROP VIEW XVLD_TMP_TST_V';
 EXCEPTION WHEN OTHERS THEN NULL; END;

END;
/

-- Compute accuracy per iteration and the average for nfolds
-- from the confusion matrix
--
SELECT a.iter, AVG(ROUND(correct/total,4)) AS accuracy
  FROM (SELECT iter, SUM(count) AS correct
          FROM dmdtxvld_c
         WHERE actual = predicted
        GROUP BY iter) a,
       (SELECT iter, SUM(count) AS total
          FROM dmdtxvld_c
        GROUP BY iter) b
 WHERE a.iter = b.iter
GROUP BY ROLLUP (a.iter);

-- Show confusion matrix by iteration and rolled up across iterations
SELECT *
  FROM (SELECT iter, actual, predicted, SUM(count) count
          FROM dmdtxvld_c
        GROUP BY ROLLUP (actual, predicted, iter))
 WHERE predicted IS NOT NULL
ORDER BY iter, actual, predicted;
