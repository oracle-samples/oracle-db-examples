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
-- The script assumes that the users ADHOC and CRITICAL have been created.
--
-- Disable current plan (MEMORY only, for sake of example)
--
alter system set resource_manager_plan = 'DEFAULT_PLAN' sid='*' scope=memory;

--
-- Drop plan “DWPLAN” if it exists
--
DECLARE
   planc NUMBER(1);
BEGIN
   SELECT COUNT(*)
   INTO   planc   
   FROM   dba_rsrc_plans
   WHERE  plan = 'DWPLAN';
   IF (planc > 0)
   THEN
      dbms_resource_manager.create_pending_area;
      dbms_resource_manager.delete_plan_cascade(plan => 'DWPLAN');
      dbms_resource_manager.submit_pending_area;
   END IF;
END;
/

--
-- Create consumer groups
--
BEGIN
   dbms_resource_manager.create_pending_area;
   dbms_resource_manager.create_consumer_group(consumer_group => 'CRITICAL',
                                                              comment=>'Critical');
   dbms_resource_manager.create_consumer_group(consumer_group => 'ADHOC',        
                                                              comment=>'Adhoc');
   dbms_resource_manager.validate_pending_area();
   dbms_resource_manager.submit_pending_area;
END;
/

--
-- Define priorities and maximum DOP for each consumer group
--
BEGIN
   dbms_resource_manager.create_pending_area;
   dbms_resource_manager.create_plan(plan=>'DWPLAN', comment=>'DW Plan');
   dbms_resource_manager.create_plan_directive(plan=>'DWPLAN',
       group_or_subplan=>'CRITICAL',comment=>'Critical',
       mgmt_p1=>40,parallel_degree_limit_p1=>4);
   dbms_resource_manager.create_plan_directive(plan=>'DWPLAN',
       group_or_subplan=>'ADHOC',comment=>'AdHoc',
       mgmt_p1=>40,parallel_degree_limit_p1=>8);
   dbms_resource_manager.create_plan_directive(plan=>'DWPLAN',
       group_or_subplan=>'OTHER_GROUPS',comment=>'Other',
       mgmt_p1=>20,parallel_degree_limit_p1=>32);
   dbms_resource_manager.validate_pending_area();
   dbms_resource_manager.submit_pending_area;
END;
/

 
--
-- Cancel long running "ADHOC" SQL (60 mins)
-- 12c Only
--
DECLARE
   vc NUMBER(1);
BEGIN
   SELECT COUNT(*)
   INTO   vc
   FROM   product_component_version
   WHERE  SUBSTR(version,1,2) = '12'
   AND    product like 'Oracle Database%';

   IF (vc != 0)
   THEN
      dbms_resource_manager.create_pending_area;
      EXECUTE IMMEDIATE '
      BEGIN dbms_resource_manager.update_plan_directive(
         plan=>''DWPLAN'',
         group_or_subplan=>''ADHOC'',
         new_switch_for_call=>TRUE,
         new_switch_elapsed_time=>3600,
         new_switch_group=>''CANCEL_SQL'');
         dbms_resource_manager.validate_pending_area();
         dbms_resource_manager.submit_pending_area;
      END; ';
   END IF;
END;
/

--
-- Define maximum idle times (10 minutes)
--
BEGIN
   dbms_resource_manager.create_pending_area;
   dbms_resource_manager.update_plan_directive(plan=>'DWPLAN',
                    group_or_subplan=>'ADHOC',new_max_idle_time=>600);
   dbms_resource_manager.update_plan_directive(plan=>'DWPLAN',
                    group_or_subplan=>'CRITICAL',new_max_idle_time=>600);
   dbms_resource_manager.validate_pending_area();
   dbms_resource_manager.submit_pending_area;
END;
/

--
-- Define maximum queue waiting time (20 mins)
--
begin
   dbms_resource_manager.create_pending_area;
   dbms_resource_manager.update_plan_directive(plan=>'DWPLAN',
      group_or_subplan=>'ADHOC',new_parallel_queue_timeout=>1200);
   dbms_resource_manager.update_plan_directive(plan=>'DWPLAN',
      group_or_subplan=>'CRITICAL',new_parallel_queue_timeout=>1200);
   dbms_resource_manager.validate_pending_area();
   dbms_resource_manager.submit_pending_area;
end;
/

 
--
-- Uncomment to allocate percentages of PX slaves to each
-- consumer group, catering for 11g/12c differences
--
/*
DECLARE
   vc NUMBER(1);
BEGIN
   SELECT COUNT(*)
   INTO   vc
   FROM   product_component_version
   WHERE  SUBSTR(version,1,2) = '11'
   AND    product like 'Oracle Database%';

   dbms_resource_manager.create_pending_area;
   IF (vc = 0)
   THEN
      EXECUTE IMMEDIATE '
      BEGIN dbms_resource_manager.update_plan_directive(plan=>''DWPLAN'',
              group_or_subplan=>''ADHOC'',new_parallel_target_percentage=>50);
           dbms_resource_manager.update_plan_directive(plan=>''DWPLAN'',
              group_or_subplan=>''CRITICAL'',new_parallel_server_limit=>50);
      END; ';
   ELSE
      EXECUTE IMMEDIATE '
      BEGIN dbms_resource_manager.update_plan_directive(plan=>''DWPLAN'',
              group_or_subplan=>''ADHOC'', new_parallel_target_percentage =>50);   
            dbms_resource_manager.update_plan_directive(plan=>''DWPLAN'',
              group_or_subplan=>''CRITICAL'', new_parallel_target_percentage =>50);
      END; ';
   END IF;
   dbms_resource_manager.validate_pending_area();
   dbms_resource_manager.submit_pending_area;
end;
/
*/


--
-- Grant required priviledges to switch consumer groups
-- 11g Only
--
DECLARE
   vc NUMBER(1);
BEGIN
   SELECT COUNT(*)
   INTO   vc
   FROM   product_component_version
   WHERE  SUBSTR(version,1,2) = '11'
   AND    product like 'Oracle Database%';

   IF (vc > 0)
   THEN
      dbms_resource_manager.create_pending_area;
      dbms_resource_manager_privs.grant_switch_consumer_group(
         grantee_name=>'PUBLIC'
        ,consumer_group=>'ADHOC'
        ,grant_option=>FALSE);

      dbms_resource_manager_privs.grant_switch_consumer_group(
         grantee_name=>'PUBLIC'
        ,consumer_group=>'CRITICAL'
        ,grant_option=>FALSE);
      dbms_resource_manager.validate_pending_area();
      dbms_resource_manager.submit_pending_area;
   END IF;
END;
/


--
-- Create consumer group mappings – assuming ADHOC and CRITICAL users exist
--
BEGIN
   dbms_resource_manager.create_pending_area;
   dbms_resource_manager.set_consumer_group_mapping
      (attribute=>'ORACLE_USER',value=>'CRITICAL',consumer_group=>'CRITICAL');
   dbms_resource_manager.set_consumer_group_mapping
      (attribute=>'ORACLE_USER',value=>'ADHOC',consumer_group=>'ADHOC');
   dbms_resource_manager.validate_pending_area();
   dbms_resource_manager.submit_pending_area;
END;
/

--
-- Important parameters
-- For example only, so scope is set to MEMORY in this case
--
alter system set parallel_force_local = FALSE sid='*' scope=memory;
alter system set parallel_degree_policy = 'AUTO' sid='*' scope=memory;
alter system set resource_manager_plan = 'DWPLAN' sid='*' scope=memory;
alter system set parallel_adaptive_multi_user = false scope=memory;



