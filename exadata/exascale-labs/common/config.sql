SET ECHO OFF

-- Shared names used throughout the Exadata Exascale labs.
-- Edit or redefine these values when adapting the workshop to a different
-- application naming scheme.

DEFINE APP_NAME              = SALES
DEFINE MAIN_PDB              = SALES_MAIN
DEFINE SNAPSHOT_NAME         = SALES_WEEKLY_SNAP
DEFINE CONSISTENT_SNAPSHOT_NAME = SALES_CONSISTENT_SNAP
DEFINE POST_REFRESH_SNAPSHOT_NAME = SALES_POST_REFRESH_SNAP
DEFINE CAROUSEL_INTERVAL     = 1 HOURS
DEFINE CAROUSEL_MAX_SNAPSHOTS = 48
DEFINE DEV_CLONE_1           = DEV_ALEX
DEFINE DEV_CLONE_2           = DEV_SARAH
DEFINE DEV_CLONE_CHILD       = DEV_JORDAN
DEFINE QA_PDB                = QA
DEFINE CI_PDB                = CI_PIPELINE

-- Oracle Clusterware configuration. Set CDB_UNIQUE_NAME for the target
-- environment before using the srvctl lifecycle helper.
DEFINE CDB_UNIQUE_NAME        = TODO_SET_CDB_UNIQUE_NAME
-- Set RAC_PDB_PLACEMENT to AUTO when existing PDB resources in the CDB were
-- created without -cardinality. Set it to ALL only when that CDB already uses
-- cardinality-based PDB resource placement.
DEFINE RAC_PDB_PLACEMENT      = AUTO
DEFINE RAC_SERVICE_PREFERRED  = TODO_SET_PREFERRED_RAC_INSTANCES
DEFINE RAC_SERVICE_CARDINALITY = UNIFORM
DEFINE MAIN_PDB_SERVICE       = SALES_MAIN_SVC
DEFINE DEV_CLONE_1_SERVICE    = DEV_ALEX_SVC
DEFINE DEV_CLONE_2_SERVICE    = DEV_SARAH_SVC
DEFINE DEV_CLONE_CHILD_SERVICE = DEV_JORDAN_SVC
DEFINE QA_PDB_SERVICE         = QA_SVC
DEFINE CI_PDB_SERVICE         = CI_PIPELINE_SVC

-- Oracle-managed containers excluded from user PDB verification output.
DEFINE ROOT_CONTAINER        = CDB$ROOT
DEFINE SEED_PDB              = PDB$SEED

-- Convenience list used by verification scripts that focus on workshop PDBs.
DEFINE LAB_PDB_LIST          = "'&&MAIN_PDB', '&&DEV_CLONE_1', '&&DEV_CLONE_2', '&&DEV_CLONE_CHILD', '&&QA_PDB', '&&CI_PDB'"

-- Set to pause-off.sql to print pause messages without waiting for Return.
DEFINE LAB_PAUSE_SCRIPT      = pause.sql

-- Set by cleanup/reset scripts before invoking common snapshot helpers.
DEFINE DROP_SNAPSHOT_NAME    = &&SNAPSHOT_NAME
