Rem
Rem $Header: tmbldemo.sql 08-dec-2004.17:47:36 shthomas Exp $
Rem
Rem blastdemo.sql
Rem
Rem Copyright (c) 2003, 2004, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      blastdemo.sql - Sample BLAST Queries
Rem
Rem    DESCRIPTION
Rem      This script demonstrates Sequence Matching Queries
Rem
Rem    NOTES
Rem     
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    ramkrish    09/15/04 - comments and cleanup
Rem    shthomas    12/08/04 - Add set pages command 
Rem    fcay        07/02/04 - fcay_dm_test_migration
Rem    mjaganna    11/04/03 - Use default parameters
Rem    cbhagwat    07/22/03 - rearrange cleanup
Rem    shthomas    06/27/03 - shthomas_txn107960
Rem    shthomas    06/25/03 - Creation
  
SET serveroutput ON
SET trimspool ON  
SET pages 10000
SET echo ON

-- BLASTP_MATCH against all the Human proteins in the SwissProt database
-- The query is a fragment of another SwissProt sequence.
--
column seq_id format a10
select T_SEQ_ID AS seq_id, score, EXPECT as evalue
  from TABLE(
       BLASTP_MATCH (
         (select sequence from query_db),
         CURSOR(SELECT seq_id, seq_data 
                  FROM swissprot
                 WHERE organism = 'Homo sapiens (Human)'),
         1,
         -1,
         0,
         0,
         'BLOSUM62',
         10,
         0,
         0,
         0,
         0,
         0)
       );

-- BLASTP_ALIGN against all the Human proteins created after 01-Jan-90 
-- in the SwissProt database
-- The query is a fragment of another SwissProt sequence.
-- select substr(T_SEQ_ID, 1, 8) AS seq_id, ALIGNMENT_LENGTH as len, 
--        Q_SEQ_START as q_strt, Q_SEQ_END as q_end, Q_FRAME,
--        T_SEQ_START as t_strt,
--        T_SEQ_END as t_end, T_FRAME, score, EXPECT as evalue
column len format 999;
column seq_id format A8;
column q_strt format 999;
column q_end format 999;
column Q_FRAME format 999;
column t_strt format 999;
column t_end format 999;
column T_FRAME format 999;

select T_SEQ_ID AS seq_id,
       ALIGNMENT_LENGTH as len, 
       Q_SEQ_START as q_strt,
       Q_SEQ_END as q_end,
       Q_FRAME,
       T_SEQ_START as t_strt,
       T_SEQ_END as t_end,
       T_FRAME, score,
       EXPECT as evalue
  from TABLE(
       BLASTP_ALIGN (
         (select sequence from query_db),
         CURSOR(SELECT seq_id, seq_data 
                  FROM swissprot
                 WHERE organism = 'Homo sapiens (Human)' AND
                       creation_date > '01-Jan-90'),
         1,
         -1,
         0,
         0,
         'BLOSUM62',
         10,
         0,
         0,
         0,
         0,
         0)
       );

-- BLASTN_MATCH against a subset of the ecoli dataset.
-- The query is a nucleotide sequence
column T_SEQ_ID format a10
select *
  from TABLE(
       BLASTN_MATCH (
         (select sequence from ecoli_query),
         CURSOR(SELECT seq_id, seq_data FROM ecoli10),
         1,
         -1,
         0,
         0,
         10,
         0,
         0,
         0,
         0,
         11,
         0,
         0)
       );

-- BLASTP_ALIGN against a small subset of the SwissProt dataset
-- The query is a fragment of another SwissProt sequence.
select *
  from TABLE(
       BLASTP_ALIGN (
         (select sequence from query_db),
         CURSOR(SELECT seq_id, seq_data FROM prot_db),
         1,
         -1,
         0,
         0,
         'BLOSUM62',
         10,
         0,
         0,
         0,
         0,
         0)
       );


-- TBLAST_MATCH (blastx) against a small subset of the SwissProt dataset
-- The query is a nucleotide sequence
-- The query is translated.

select *
  from TABLE(
       TBLAST_MATCH (
         (select sequence from ecoli_query),
         CURSOR(SELECT seq_id, seq_data FROM prot_db),
         1,
         -1,
         'blastx',
         1,
         0,
         0,
         'BLOSUM62',
         10,
         0,
         0,
         0,
         0,
         0)
       );

-- TBLASTX (tblastn) against a subset of the ecoli dataset
-- The query is a fragment of a SwissProt sequence.
-- The database is translated.

select *
  from TABLE(
       TBLAST_MATCH (
         (select sequence from query_db),
         CURSOR(SELECT seq_id, seq_data FROM ecoli10),
         1,
         -1,
         'tblastn',
         1,
         0,
         0,
         'BLOSUM62',
         10,
         0,
         0,
         0,
         0,
         0)
       );

-- TBLASTX (tblastx) against a subset of the ecoli dataset
-- The query is a nucleotide sequence
-- Both query and the database are translated.

select *
  from TABLE(
       TBLAST_MATCH (
         (select sequence from ecoli_query),
         CURSOR(SELECT seq_id, seq_data FROM ecoli10),
         1,
         -1,
         'tblastx',
         1,
         0,
         0,
         'BLOSUM62',
         10,
         0,
         0,
         0,
         0,
         0)
       );
