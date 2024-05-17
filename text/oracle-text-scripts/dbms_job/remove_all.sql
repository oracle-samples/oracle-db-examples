begin
  for c in ( select job from user_jobs ) loop
    dbms_job.remove(c.job);
  end loop;
end;
/
