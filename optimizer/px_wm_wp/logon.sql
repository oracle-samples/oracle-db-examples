--
-- DISCLAIMER:
-- This script is provided for educational purposes only. It is
-- NOT supported by Oracle World Wide Technical Support.
-- The script has been tested and appears to work as intended.
-- You should always run new scripts initially
-- on a test instance.
--
-- Script Vesion 0.1 - TEST
--
--
CREATE OR REPLACE TRIGGER px_logon_trigger
  AFTER LOGON
  ON DATABASE
DECLARE
  mapped_cgroup_count number;
BEGIN
  SELECT COUNT(*)
  INTO   mapped_cgroup_count
  FROM   dba_rsrc_group_mappings
  WHERE  attribute = 'ORACLE_USER'
  AND    value     = USER
  AND    consumer_group IN ('ADHOC', 'CRITICAL')
  AND    status IS NULL;  

  IF mapped_cgroup_count > 0
  THEN
    EXECUTE IMMEDIATE 'ALTER SESSION SET parallel_degree_policy = ''AUTO''';
  END IF;
END px_logon_trigger;
/

