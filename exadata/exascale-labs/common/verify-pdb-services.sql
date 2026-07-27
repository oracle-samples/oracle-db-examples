SET ECHO OFF

@@helpers.sql
@@config.sql

-- RAC-aware PDB service placement. Excludes root and seed services.
PROMPT PDB services

SELECT s.inst_id,
       i.instance_name,
       s.con_id,
       s.pdb AS pdb_name,
       s.name AS service_name,
       s.network_name
FROM   gv$services s
       JOIN gv$instance i
         ON i.inst_id = s.inst_id
WHERE  s.pdb NOT IN ('&&ROOT_CONTAINER', '&&SEED_PDB')
ORDER  BY s.pdb, s.name, s.inst_id;

PROMPT Service placement summary

SELECT pdb AS pdb_name,
       name AS service_name,
       COUNT(DISTINCT inst_id) AS service_instances
FROM   gv$services
WHERE  pdb NOT IN ('&&ROOT_CONTAINER', '&&SEED_PDB')
GROUP  BY pdb, name
ORDER  BY pdb, name;
