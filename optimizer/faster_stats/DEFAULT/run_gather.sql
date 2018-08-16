--
-- This starts a batch window to execute auto stats
-- immediately. In this case we are just using
-- the default maintenance plan.
--
begin
  begin
    dbms_scheduler.drop_window('TEST_WINDOW',true);
  exception when others then
    if (sqlcode != -27476) then
      raise;
    end if;
  end;

  dbms_scheduler.create_window(
    window_name     => 'TEST_WINDOW',
    duration        =>  numtodsinterval(20, 'minute'),
    resource_plan   => 'DEFAULT_MAINTENANCE_PLAN',
    repeat_interval => 'FREQ=DAILY;INTERVAL=1');
  dbms_scheduler.add_group_member(
    group_name  => 'MAINTENANCE_WINDOW_GROUP',
    member      => 'TEST_WINDOW');
  dbms_scheduler.enable(name => 'TEST_WINDOW');
  dbms_auto_task_admin.enable('auto optimizer stats collection',NULL,
                              'TEST_WINDOW');
--dbms_auto_task_admin.enable('sql tuning advisor',NULL,
--                            'TEST_WINDOW');
--dbms_auto_task_admin.enable('auto space advisor',NULL,
--                            'TEST_WINDOW');
end;
/


