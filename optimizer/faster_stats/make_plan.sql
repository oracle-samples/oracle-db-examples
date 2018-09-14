--
-- This script will create a new maintenance plan that can be
-- used by our chosen batch window. In this way we can have
-- a consistent RM plan when the batch window is open or closed.
--
@cadm

set echo on
@drop_plan

begin
  dbms_resource_manager.clear_pending_area;
  dbms_resource_manager.create_pending_area();
  dbms_resource_manager.create_plan('DB_RM_PLAN', 'RM Plan for Managing System Resource');
  dbms_resource_manager.create_plan_directive(
        plan                         => 'DB_RM_PLAN',
        group_or_subplan             => 'ORA$AUTOTASK',
        mgmt_p1                  => 5,
        max_utilization_limit    => 90,
        parallel_degree_limit_p1 => 4);
  dbms_resource_manager.create_plan_directive(
        plan                         => 'DB_RM_PLAN',
        group_or_subplan             => 'OTHER_GROUPS',
        mgmt_p1                  => 20);
  dbms_resource_manager.create_plan_directive(
        plan                         => 'DB_RM_PLAN',
        group_or_subplan             => 'SYS_GROUP',
        mgmt_p1                  => 75);
  DBMS_RESOURCE_MANAGER.VALIDATE_PENDING_AREA();
  dbms_resource_manager.submit_pending_area();
end;
/

ALTER SYSTEM SET RESOURCE_MANAGER_PLAN = 'DB_RM_PLAN' scope = memory;

show parameter resource_manager_plan
