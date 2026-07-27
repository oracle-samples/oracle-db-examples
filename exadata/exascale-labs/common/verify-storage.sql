SET ECHO OFF

@@helpers.sql

-- Uses CDB_DATA_FILES for size and autoextend metadata.
PROMPT PDB storage summary

WITH pdbs AS (
    SELECT con_id,
           pdb_name
    FROM   cdb_pdbs
),
datafiles AS (
    SELECT con_id,
           file_id,
           bytes,
           autoextensible,
           maxbytes
    FROM   cdb_data_files
)
SELECT p.pdb_name,
       d.con_id,
       COUNT(*) AS files,
       ROUND(SUM(d.bytes) / 1024 / 1024 / 1024, 2) AS allocated_gb,
       ROUND(SUM(CASE WHEN d.autoextensible = 'YES' THEN d.maxbytes ELSE d.bytes END)
             / 1024 / 1024 / 1024, 2) AS autoextend_max_gb
FROM   datafiles d
       LEFT JOIN pdbs p
         ON p.con_id = d.con_id
WHERE  p.pdb_name IS NOT NULL
GROUP  BY p.pdb_name, d.con_id
ORDER  BY p.pdb_name;

-- TODO: Track Exadata Exascale physical storage metrics in docs/todo.md.
