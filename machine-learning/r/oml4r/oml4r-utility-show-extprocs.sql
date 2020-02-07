--##################################################################
--##
--## Oracle Machine Learning for R 
--## 
--## Utility to find Extprocs
--##
--## (c) 2020 Oracle Corporation
--##
--###################################################################

create or replace procedure ShowExtProcs is
  -- Cursor to find all running extprocs
  Cursor GetExtprocs is
    select agt.process, agt.agent_id, sess.hs_session_id 
      from v$hs_agent agt, v$hs_session sess
      where agt.agent_id = sess.agent_id;

  -- Cursor to convert HS_SESSION_ID (extproc session) to the SQL ID
  -- (SQL statement) that invoked the extproc.  Note that we want to find
  -- the newest sample
  Cursor GetSqlid (hs_session_id number) is
    select sql_id, qc_session_id
      from v$active_session_history ash
      where event='External Procedure call' and
            hs_session_id=ash.p1 and
            qc_session_id is not null
      order by sample_time desc;

  -- Get the SQL text associated with the SQL ID
  Cursor GetSqltext (sqlid varchar2) is
    select substr(sql_text, 0, 200) from v$sql where sql_id=sqlid;

  v_sqlid varchar2(20);
  v_sqltext varchar2(200);
  v_session_id number;
  v_found boolean := FALSE;
  
  -- Use these types to create a collection of extprocs and their associated
  -- SQL IDs found in each session.
  type sqltabtype is table of DBMS_SQL.Number_Table index by varchar2(20);
  type sesstabtype is table of sqltabtype index by binary_integer;
  v_sesstab sesstabtype;
  v_sqltab sqltabtype;
begin
  -- Get each running extproc and associated SQL ID and add it to the 
  -- collection.
  for extproc in GetExtprocs loop
    open GetSqlid(extproc.hs_session_id);
    fetch GetSqlid into v_sqlid, v_session_id;
    close GetSqlid;

    -- Add the extproc to the collection if there is a SQL ID for it.
    if (v_sqlid is not null) then
      v_sesstab(v_session_id)(v_sqlid)(extproc.process) := extproc.agent_id;
      v_found := TRUE;
    end if;
  end loop;

  if (v_found = TRUE) then
    -- At least one extproc was found so walk back through the collection 
    -- and display the results
    for a_session in v_sesstab.first..v_sesstab.last loop
      if (v_sesstab.exists(a_session)) then
        
        dbms_output.put_line('QC Session : ' || a_session);
        dbms_output.put_line('==================');

        v_sqltab := v_sesstab(a_session);
        v_sqlid := v_sqltab.first;

        -- Loop through all SQL IDs recorded for this QC session
        while (v_sqlid is not null) loop
          open GetSqltext(v_sqlid);
          fetch GetSqltext into v_sqltext;
          close GetSqltext;

          dbms_output.put_line('SQL ID: ' || v_sqlid);
          dbms_output.put_line('SQL Text: ' || v_sqltext || '...');
          dbms_output.put_line('Extproc ID / PID:');
	
          -- Get the Extproc IDs/PIDs executing this SQL ID
          for i in v_sqltab(v_sqlid).first..v_sqltab(v_sqlid).last loop
            if (v_sqltab(v_sqlid).exists(i)) then
              dbms_output.put_line(v_sqltab(v_sqlid)(i) || ' / ' || i);
            end if;
          end loop;
 
          dbms_output.put_line('-----------------------');

	  v_sqlid := v_sqltab.next(v_sqlid);
        end loop;
      end if;
    end loop;

  else
    dbms_output.put_line('No matching extprocs found');
  end if;
end;
/
show errors;
