SET ECHO OFF

@@helpers.sql
@@config.sql

-- RAC-aware PDB state. Excludes only the seed container.
PROMPT PDB state across RAC instances

SELECT p.inst_id,
       i.instance_name,
       p.con_id,
       p.name AS pdb_name,
       open_mode,
       restricted,
       open_time
FROM   gv$pdbs p
       JOIN gv$instance i
         ON i.inst_id = p.inst_id
WHERE  p.name <> '&&SEED_PDB'
ORDER  BY p.name, p.inst_id;

PROMPT PDB open summary

SELECT name AS pdb_name,
       COUNT(*) AS total_instances,
       SUM(CASE WHEN open_mode = 'READ WRITE' THEN 1 ELSE 0 END) AS read_write_instances,
       SUM(CASE WHEN open_mode = 'READ ONLY' THEN 1 ELSE 0 END) AS read_only_instances
FROM   gv$pdbs
WHERE  name <> '&&SEED_PDB'
GROUP  BY name
ORDER  BY name;
