Rem
Rem $Header: tk_datamining/tmdm/sql/txfdemo.sql /main/2 2010/12/10 12:12:54 xbarr Exp $
Rem
Rem xfdemo.sql
Rem
Rem Copyright (c) 2003, 2010, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      xfdemo.sql - Sample program for DBMS_DATA_MINING_TRANSFORM package.  
Rem    DESCRIPTION
Rem      This script demonstrates the use of DBMS_DATA_MINING_TRANSFORM
Rem      package. 
Rem
Rem    NOTES
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    xbarr       12/01/10 - move out dm_demo_drop_object
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    dmukhin     09/03/03 - name changes
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    ramkrish    06/26/03 - set trimspool on
Rem    fcay        06/23/03 - Update copyright notice
Rem    cbhagwat    06/18/03 - cbhagwat_txn107745
Rem    cbhagwat    06/16/03 - Creation

SET serveroutput ON
SET trimspool ON
SET pages 10000

------------------------------------
-- NUMERICAL AND CATEGORICAL BINNING
------------------------------------
  execute dm_demo_drop_object('xf_sample_num_def','table');
  execute dm_demo_drop_object('xf_sample_cat_def','table');
  execute dm_demo_drop_object('xf_sample_bin_prepared','view');
  execute dm_demo_drop_object('xf_sample_cat','view');
-- Create bin definitions 
BEGIN
  -- Make a numerical bin definition table
  dbms_output.put_line('Create definition tables');
  dbms_data_mining_transform.create_bin_num (
    bin_table_name  => 'xf_sample_num_def');
  dbms_data_mining_transform.create_bin_cat (
    bin_table_name  => 'xf_sample_cat_def');        

  -- create bin definitions for select columns
  dbms_output.put_line('Insert bin definitions');
  dbms_data_mining_transform.insert_bin_num_eqwidth (
    bin_table_name  => 'xf_sample_num_def',
    data_table_name => 'mining_data_build',
    bin_num         => 10,
    exclude_list    => dbms_data_mining_transform.column_list (
                       'WKS_SINCE_LAST_PURCH',
                       'AFFINITY_CARD',
                       'average___items_purchased',
                       'NO_DIFFERENT_KIND_ITEMS',
                       'YRS_RESIDENCE',
                       'DISABLE_COOKIES',
                       'PROMO_RESPOND',
                       'MAILING_LIST',
                       'SR_CITIZEN',
                       'BULK_PACK_DISKETTES',
                       'FLAT_PANEL_MONITOR',
                       'HOME_THEATER_PACKAGE',
                       'BOOKKEEPING_APPLICATION',
                       'PRINTER_SUPPLIES',
                       'Y_BOX_GAMES',
                       'OS_DOC_SET_KANJI',
                       'PETS',
                       'id'),
    round_num       => 0
  );

  -- Bin Workclass (categorical)
  dbms_data_mining_transform.insert_bin_cat_freq (
    bin_table_name  => 'xf_sample_cat_def',
    data_table_name => 'mining_data_build',
    bin_num         => 5,
    exclude_list    => dbms_data_mining_transform.column_list (
                       'education',
                       'MARITAL_STATUS',
                       'OCCUPATION',
                       'HOUSEHOLD_SIZE',
                       'TOP_REASON_FOR_SHOPPING',
                       'GENDER',
                       'SHIPPING_ADDRESS_COUNTRY'),
    default_num       => 0
  );
  -- Make default bin NULL
  EXECUTE IMMEDIATE
    'DELETE FROM xf_sample_cat_def WHERE val IS NULL';

  dbms_output.put_line('Modify bin definition tables');
END;
/

-- Adjust categorical bin definition table
-- SELECT * FROM xf_sample_cat_def;
-- "?" gets assigned to bin 4, instead map "SelfEI"
UPDATE xf_sample_cat_def
  SET val = 'Sta-gov' WHERE bin = '4';

-- Also, add an "Other bin" (instead of NULL)
INSERT INTO xf_sample_cat_def (col,val,bin)
VALUES ('WORKCLASS',NULL,'100');
COMMIT;
--SELECT * FROM xf_sample_cat_def

-- Adjust numerical definition table
--SELECT * FROM xf_sample_num_def;
-- insert bin definitions for yrs_residence
INSERT INTO xf_sample_num_def (col,val,bin)
VALUES ('YRS_RESIDENCE',10,1);
INSERT INTO xf_sample_num_def (col,val,bin)
VALUES ('YRS_RESIDENCE',14,2);
COMMIT;
--SELECT * FROM xf_sample_num_def;

-- xform  
BEGIN 
  -- Create the transformed view
  dbms_output.put_line('Transform data using definition tables');
  dbms_data_mining_transform.xform_bin_cat (
    bin_table_name  => 'xf_sample_cat_def',
    data_table_name => 'mining_data_build',
    xform_view_name => 'xf_sample_cat');    
  dbms_data_mining_transform.xform_bin_num (
    bin_table_name  => 'xf_sample_num_def',
    data_table_name => 'xf_sample_cat',
    xform_view_name => 'xf_sample_bin_prepared');    
END;
/
-- select * from xf_sample_bin_prepared;

----------------
-- NORMALIZATION
----------------
  execute dm_demo_drop_object('xf_sample_norm','table');
  execute dm_demo_drop_object('xf_sample_norm_prepared','view');
-- minmax, zscore
BEGIN
  -- Make a numerical bin definition table
  dbms_output.put_line('Create normalization table');
  dbms_data_mining_transform.create_norm_lin (
    norm_table_name => 'xf_sample_norm');

  dbms_output.put_line('Create normalization details');
  -- Normalize data  ( zscore)  
  dbms_data_mining_transform.insert_norm_lin_zscore (
    norm_table_name => 'xf_sample_norm',
    data_table_name => 'mining_data_build',
    exclude_list    => dbms_data_mining_transform.column_list (
                       'WKS_SINCE_LAST_PURCH',
                       'AFFINITY_CARD',
                       'NO_DIFFERENT_KIND_ITEMS',
                       'DISABLE_COOKIES',
                       'PROMO_RESPOND',
                       'MAILING_LIST',
                       'SR_CITIZEN',
                       'BULK_PACK_DISKETTES',
                       'FLAT_PANEL_MONITOR',
                       'HOME_THEATER_PACKAGE',
                       'BOOKKEEPING_APPLICATION',
                       'PRINTER_SUPPLIES',
                       'Y_BOX_GAMES',
                       'OS_DOC_SET_KANJI',
                       'PETS',
                       'id',
                       'AGE'),
    round_num       => 0
  );        

  -- Normalize age using minmax
  dbms_data_mining_transform.insert_norm_lin_minmax (
    norm_table_name => 'xf_sample_norm',
    data_table_name => 'mining_data_build',
    exclude_list    => dbms_data_mining_transform.column_list (
                       'WKS_SINCE_LAST_PURCH',
                       'AFFINITY_CARD',
                       'NO_DIFFERENT_KIND_ITEMS',
                       'DISABLE_COOKIES',
                       'PROMO_RESPOND',
                       'MAILING_LIST',
                       'SR_CITIZEN',
                       'BULK_PACK_DISKETTES',
                       'FLAT_PANEL_MONITOR',
                       'HOME_THEATER_PACKAGE',
                       'BOOKKEEPING_APPLICATION',
                       'PRINTER_SUPPLIES',
                       'Y_BOX_GAMES',
                       'OS_DOC_SET_KANJI',
                       'PETS',
                       'id'),
    round_num       => 0
  );        
  dbms_output.put_line('Modify normalization details');
END;
/

--SELECT * FROM xf_sample_norm;  
-- Modify normalization table
-- Rescale age from -1 to 1, not 0 to 1
UPDATE xf_sample_norm SET shift = shift + scale/2
WHERE col = 'AGE';
UPDATE xf_sample_norm SET scale = scale/2
WHERE col = 'AGE';
COMMIT;

-- Create the transformed view
BEGIN
  dbms_output.put_line('Normalize the data');
  dbms_data_mining_transform.xform_norm_lin (
    norm_table_name => 'xf_sample_norm',
    data_table_name => 'mining_data_build',       
    xform_view_name => 'xf_sample_norm_prepared');    
END;
/
-- select * from xf_sample_norm_prepared;
