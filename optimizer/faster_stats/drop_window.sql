--
-- Drop the test maintenance window - this will stop running jobs too
--
@cadm

begin
  begin
    dbms_scheduler.drop_window('TEST_WINDOW',true);
  exception when others then
    if (sqlcode != -27476) then
      raise;
    end if;
  end;
end;
/


