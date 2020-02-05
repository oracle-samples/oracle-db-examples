Rem
Rem $Header: dmbldemo_n.sql 21-jan-2005.10:53:23 jcjeon Exp $
Rem
Rem dmbldemo_n.sql
Rem
Rem Copyright (c) 2005, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      dmbldemo_n.sql - Sample BLAST Queries with NLS
Rem
Rem    DESCRIPTION
Rem      This script demonstrates Sequence Matching Queries
Rem
Rem    NOTES
Rem      Refer to dmbldemo.sql for detail
Rem
Rem    MODIFIED   (MM/DD/YY) 
Rem    jcjeon      01/21/05 - jcjeon_dmsh_nls_1
Rem    jcjeon      01/18/05 - Created
Rem
  
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
                 WHERE organism = '~H~o~m~o ~s~a~p~i~e~n~s (Human)'),
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
                 WHERE organism = '~H~o~m~o ~s~a~p~i~e~n~s (Human)' AND
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
