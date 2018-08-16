--
-- Drop the test RM plan
--
@cadm

ALTER SYSTEM SET RESOURCE_MANAGER_PLAN = '' scope = memory;

declare
  plan_exists exception;
  pragma exception_init (plan_exists,-29358); 
begin
  dbms_resource_manager.create_pending_area();
  dbms_resource_manager.delete_plan('DB_RM_PLAN');
  dbms_resource_manager.submit_pending_area();
  exception 
     when plan_exists then null;
end;
/

