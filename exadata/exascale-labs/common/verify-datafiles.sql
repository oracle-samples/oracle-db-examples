SET ECHO OFF

@@helpers.sql

-- Uses CDB_DATA_FILES so OMF file names and autoextend metadata are visible.
PROMPT PDB datafiles

WITH pdbs AS (
    SELECT con_id,
           pdb_name
    FROM   cdb_pdbs
)
SELECT p.pdb_name,
       d.con_id,
       d.tablespace_name,
       d.file_id,
       d.file_name,
       ROUND(d.bytes / 1024 / 1024, 2) AS bytes_mb,
       d.autoextensible,
       ROUND(d.maxbytes / 1024 / 1024, 2) AS maxbytes_mb
FROM   cdb_data_files d
       LEFT JOIN pdbs p
         ON p.con_id = d.con_id
WHERE  p.pdb_name IS NOT NULL
ORDER  BY p.pdb_name, d.tablespace_name, d.file_id;
