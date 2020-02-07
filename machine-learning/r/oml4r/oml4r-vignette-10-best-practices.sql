--##################################################################
--##
--## Oracle Machine Learning for R Vignette 
--## 
--## Best Practices
--##
--## (c) 2020 Oracle Corporation
--##
--###################################################################

-- Table parallelism
alter table flights noparallel;

alter table flights parallel 4;

SELECT table_name, degree 
   FROM user_tables 
   WHERE table_name = 'FLIGHTS';

-- Using parallel query hint

-- Set up group Eval package
CREATE OR REPLACE PACKAGE flightsPkg AS
  TYPE cur IS REF CURSOR RETURN FLIGHTS%ROWTYPE;
  END flightsPkg;
   /

--Set up group Eval function
CREATE OR REPLACE FUNCTION flightsGroupEval(
  inp_cur  flightsPkg.cur,
  par_cur  SYS_REFCURSOR, 
  out_qry  VARCHAR2,
  grp_col  VARCHAR2,
  exp_txt  CLOB)
RETURN SYS.AnyDataSet
PIPELINED PARALLEL_ENABLE (PARTITION inp_cur BY HASH(MONTH))
CLUSTER inp_cur BY (MONTH)
USING rqGroupEvalImpl;
/

-- R function definition
alter table FLIGHTS parallel;

-- Drop GroupingExample script, if it exists
begin
  sys.rqScriptDrop('GroupingExample');
end;
/

-- Create GroupingExample script
begin
  sys.rqScriptCreate('GroupingExample',
    'function(dat) {
      res <- coef(lm(ARR_DELAY ~ DEST, data=dat))
      res
      }');
end;
/

SELECT *
 from table(flightsGroupEval(
    cursor(SELECT /*+ parallel(t, 4) */ * FROM FLIGHTS t),
    cursor(SELECT 1 as "ore.connect" FROM dual),
    NULL, 'MONTH', 'GroupingExample'));
         
         
begin
  sys.rqScriptDrop('GroupingExample');
end;
/

---- Associating external procedures with SQL IDs 
-- Grouping Related extprocs

-- Active Session History(ASH): Oracle samples the database every second and stores details of every session that is considered active, 
-- waiting on a non-idle wait event or executing on a CPU. These details are exposed via the data dictionary view v$active_session_history 

SELECT * FROM v$active_session_history
  ORDER BY SAMPLE_TIME_UTC

-- The underlying storage for ASH is a circular memory buffer
-- Once the buffer is full then older entries are overwritten by new entries

-- What are the earliest available entries in ASH?

SELECT MIN(sample_time) AS min_sample_time_utc
  FROM  v$active_session_history;
  
       
-- SQL Monitor currently breaks out SQL execution into parallel query slaves, but they are not mapped directly to extproc PIDs
-- In Oracle Database 12.2 and later, the the P1 value (P1TEXT - HS_SESSION_ID) is recorded for 'External Procedure call' 
-- events in ASH. The HS_SESSION_ID allows us to create a link between an ASH sample, and two other views: 
-- V$HS_SESSION amd V$HS_AGENT to get the extproc agent PID.

-- V$HS_AGENT view: currently running extproc agents
-- V$HS_SESSION view: currently running Oracle processes associated with agents


-- This function will find extprocs running as part of a PQ slave process and 
-- display the extproc PID along with the SQL ID/SQL Text that spawned the 
-- extproc. To create the ShowExtrpocs procedure, save to a file ShowExtprocs.sql 
-- and run the script, e.g., @ShowExtrpocs.sql

-- Successful creation of the procedure will return:
--SQL> @ShowExtprocs.sql
--Procedure created.
--No errors.

-- To execute the function, run the command as sys or request select permission
-- on the Database views queried in the script

--SQL> execute ShowExtprocs

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

--execute ShowExtprocs Procedure as sys
set server output on
begin
showExtProcs
end;
/
















