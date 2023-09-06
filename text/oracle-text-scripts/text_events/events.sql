-- Sample usage 
-- ------------
--
-- select ctx_event.check_trace() from dual;
--
-- select ctx_event.is_trace_set(1073741824) from dual;
--
-- exec ctx_event.add_trace(1073741824);
--
-- exec ctx_event.remove_trace(1073741824);
--
-- exec ctx_event.add_trace(536870912);
-- 
-- exec ctx_event.clear_trace();

CREATE OR REPLACE PACKAGE ctx_event AS
  FUNCTION   get_trace                RETURN INTEGER;
  PROCEDURE  add_trace    (level INTEGER);
  PROCEDURE  remove_trace (level INTEGER);
  PROCEDURE  clear_trace;
  FUNCTION   is_trace_set (level INTEGER) RETURN BOOLEAN;
END ctx_event;
/
show errors

CREATE  OR REPLACE  PACKAGE BODY ctx_event AS

PROCEDURE checkTrace(level INTEGER) IS
  val      int;
  bitcount int ;
BEGIN
  val  := level;
  bitcount := 0;
  WHILE val > 0 LOOP
    val := bitand(val, val-1);
    bitcount := bitcount + 1;
  END LOOP;
  IF bitcount != 1 THEN
    RAISE VALUE_ERROR;
  END IF;
END checkTrace;
 
PROCEDURE  add_trace(level INTEGER) IS
  event_level      INTEGER;
  temp_event_level INTEGER;
BEGIN
  checkTrace(level);
  sys.dbms_system.read_ev(30579,event_level);
  temp_event_level := bitand(event_level,level);
  IF temp_event_level !=  level THEN
    event_level   :=  event_level + level;
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET EVENTS ''30579 trace name context forever, level ' || event_level || '''';
  END IF;
END add_trace;

PROCEDURE remove_trace(level INTEGER) IS
  event_level INTEGER;
  temp_event_level INTEGER;
BEGIN
  checkTrace(level);
  sys.dbms_system.read_ev(30579,event_level);
  temp_event_level := bitand(event_level,level);
  IF event_level =  level THEN
    event_level   :=   event_level - level ;
    EXECUTE IMMEDIATE 'ALTER SYSTEM SET EVENTS ''30579 trace name context forever, level ' || event_level || '''';
  END IF;
END remove_trace;

PROCEDURE clear_trace IS
BEGIN
  EXECUTE IMMEDIATE 'ALTER SYSTEM SET EVENTS ''30579 trace name context off ''';
END clear_trace;

FUNCTION  is_trace_set(level INTEGER) return BOOLEAN IS
  event_level number;
BEGIN
  checkTrace(level);  
  sys.dbms_system.read_ev(30579,event_level);
  event_level := bitand(event_level,level);
  IF event_level =  level THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END is_trace_set;

FUNCTION get_trace return INTEGER IS
  event_level number;
BEGIN
  sys.dbms_system.read_ev(30579,event_level);
  RETURN event_level;
END get_trace;

END ctx_event;
/ 

show errors
