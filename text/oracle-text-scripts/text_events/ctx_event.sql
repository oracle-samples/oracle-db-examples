--
-- Sample usage 
-- ------------
--
-- select ctx_event.get_trace() from dual;
--
-- select ctx_event.is_trace_set(1073741824) from dual;
--
-- ( set Query performance improvements )
-- exec ctx_event.add_trace(1073741824);
-- ( set Crawling performance improvements )
-- exec ctx_event.add_trace(536870912);
-- 
-- exec ctx_event.remove_trace(1073741824);
--
-- exec ctx_event.clear_trace();

CREATE OR REPLACE PACKAGE ctx_event AS
   FUNCTION   get_traces   ( base  INTEGER default 10 ) RETURN VARCHAR2;
   PROCEDURE  add_trace    ( level INTEGER );
   PROCEDURE  remove_trace ( level INTEGER );
   PROCEDURE  clear_trace;
   FUNCTION   is_trace_set ( level INTEGER )                   RETURN INTEGER;
END ctx_event;
/
show errors

CREATE OR REPLACE  PACKAGE BODY ctx_event AS

TEXTEVENT CONSTANT INTEGER := 30579;

PROCEDURE checkTrace(level INTEGER) IS
   val      int;
   bitcount int ;
BEGIN
   val  := level;
   bitcount := 0;
   WHILE val > 0 LOOP
      val := BITAND(val, val-1);
      bitcount := bitcount + 1;
   END LOOP;
   IF bitcount != 1 THEN
      RAISE_APPLICATION_ERROR(-20102, 'Event level not valid - number must a power of two');
   END IF;
END checkTrace;
 
PROCEDURE  add_trace(level INTEGER) IS
   event_level      INTEGER;
   temp_event_level INTEGER;
BEGIN
   checkTrace(level);
   sys.dbms_system.read_ev( TEXTEVENT, event_level );
   temp_event_level := BITAND( event_level,level );
   IF temp_event_level != level THEN
      event_level   :=  event_level + level;
      EXECUTE IMMEDIATE 'ALTER SYSTEM SET EVENTS '''||TEXTEVENT||' trace name context forever, level ' || event_level || '''';
   END IF;
END add_trace;

PROCEDURE remove_trace(level INTEGER) IS
   event_level INTEGER;
   temp_event_level INTEGER;
BEGIN
   checkTrace(level);
   sys.dbms_system.read_ev( TEXTEVENT, event_level );
   temp_event_level := BITAND( event_level, level );
   IF event_level =  level THEN
      event_level   :=   event_level - level ;
      EXECUTE IMMEDIATE 'ALTER SYSTEM SET EVENTS '''||TEXTEVENT||' trace name context forever, level ' || event_level || '''';
   END IF;
END remove_trace;

PROCEDURE clear_trace IS
BEGIN
   EXECUTE IMMEDIATE 'ALTER SYSTEM SET EVENTS '''||TEXTEVENT||' trace name context off ''';
END clear_trace;

FUNCTION  is_trace_set(level INTEGER) return INTEGER IS
   event_level number;
BEGIN
   checkTrace(level);  
   sys.dbms_system.read_ev( TEXTEVENT, event_level );
   event_level := BITAND( event_level, level );
   IF event_level = level THEN
      RETURN 1;
   ELSE
      RETURN 0;
   END IF;
END is_trace_set;

FUNCTION get_traces (base INTEGER default 10) RETURN VARCHAR2 IS
   event_level NUMBER;
   event_str   VARCHAR2(255) := '';
   powerOfTwo  INTEGER       := 1;
   comma       VARCHAR2(1)   := '';    
BEGIN
   sys.dbms_system.read_ev( TEXTEVENT, event_level );
   while powerOfTwo <= event_level LOOP
      IF BITAND( event_level, powerOfTwo ) > 0 THEN
         if base = 16 THEN
            event_str := event_str || comma || LPAD( LTRIM( TO_CHAR( powerOfTwo, 'XXXXXXXX') ), 8, '0' );
         ELSE 
            event_str := event_str || comma || TO_CHAR( powerOfTwo );
         END IF;
         comma := ',';
      END IF;
      powerOfTwo := powerOfTwo * 2;
   END LOOP;
   RETURN event_str;
END get_traces;

END ctx_event;
/ 

show errors
