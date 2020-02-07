Rem
Rem $Header: tk_datamining/tmdm/sql/tmdemoev.sql /main/2 2014/12/19 11:46:23 jiangzho Exp $
Rem
Rem tmdemoev.sql
Rem
Rem Copyright (c) 2014, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      tmdemoev.sql - evaluate models
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jiangzho    11/19/14 - jiang
Rem    jiangzho    11/19/14 - Created
Rem

SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100
column cust_marital_status format a32
column PARTITION_NAME format a32

select   cust_id, affinity_card, cust_marital_status,
             cluster_id(OC_SH_Clus_samplep using *) probability,
             ora_dm_partition_name(OC_SH_Clus_samplep using *) partition_name
 from mining_data_build_v where mod(cust_id,10)=1 
order by cust_id;

select   cust_id, affinity_card, cust_marital_status,
             cluster_id(KM_SH_Clus_samplep using *) probability,
             ora_dm_partition_name(KM_SH_Clus_samplep using *) partition_name
 from mining_data_build_v where mod(cust_id,10)=1 
order by cust_id;


