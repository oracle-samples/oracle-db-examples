--
-- This modifies the default maintenance resource
-- management plan as described in the blog
-- post. 
--
connect / as sysdba

exec dbms_resource_manager.clear_pending_area

begin
  dbms_resource_manager.create_pending_area();
  dbms_resource_manager.update_plan_directive(
        plan                         => 'DEFAULT_MAINTENANCE_PLAN',
        group_or_subplan             => 'ORA$AUTOTASK',
        new_mgmt_p1                  => 5,
        new_max_utilization_limit    => 90,
        new_parallel_degree_limit_p1 => 4);
  dbms_resource_manager.update_plan_directive(
        plan                         => 'DEFAULT_MAINTENANCE_PLAN',
        group_or_subplan             => 'OTHER_GROUPS',
        new_mgmt_p1                  => 20);
  dbms_resource_manager.update_plan_directive(
        plan                         => 'DEFAULT_MAINTENANCE_PLAN',
        group_or_subplan             => 'SYS_GROUP',
        new_mgmt_p1                  => 75);
  dbms_resource_manager.validate_pending_area();
  dbms_resource_manager.submit_pending_area();
end;
/

