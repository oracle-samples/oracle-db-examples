connect / as sysdba

COLUMN alme     HEADING "Allocated MB" FORMAT 99999D9
COLUMN usme     HEADING "Used MB"      FORMAT 99999D9
COLUMN frme     HEADING "Freeable MB"  FORMAT 99999D9
COLUMN mame     HEADING "Max MB"       FORMAT 99999D9
COLUMN username                        FORMAT a15
COLUMN program                         FORMAT a22
COLUMN sid                             FORMAT a5
COLUMN spid                            FORMAT a8
SET LINESIZE 300
SET PAGESIZE 60

-- Get the overall memory usage for all processes

SELECT * FROM
(  SELECT s.username, SUBSTR(s.sid,1,5) sid, p.spid, logon_time,
       SUBSTR(s.program,1,22) program , s.process pid_remote,
       s.status,
       ROUND(pga_used_mem/1024/1024) usme,
       ROUND(pga_alloc_mem/1024/1024) alme,
       ROUND(pga_freeable_mem/1024/1024) frme,
       ROUND(pga_max_mem/1024/1024) mame
   FROM  v$session s,v$process p
   WHERE p.addr=s.paddr
   ORDER BY pga_max_mem desc,logon_time
) where rownum <= 50;

-- Now do a dump for the top process

VARIABLE v_sid NUMBER
VARIABLE v_pid NUMBER

begin
   SELECT MAX(SUBSTR(s.sid,1,5)) INTO :v_sid
   FROM v$session s, v$process p
   WHERE p.addr=s.paddr
   AND   pga_alloc_mem =
      ( SELECT MAX(pga_alloc_mem) FROM v$process );

end;
/

prompt Max memory for process:
print v_sid

COLUMN category      HEADING "Category"
COLUMN allocated     HEADING "Allocated bytes"
COLUMN used          HEADING "Used bytes"
COLUMN max_allocated HEADING "Max allocated bytes"
SELECT pid, category, allocated, used, max_allocated
FROM   v$process_memory
WHERE  pid = (SELECT pid
              FROM   v$process
              WHERE  addr= (select paddr
                            FROM   v$session
                            WHERE  sid = :v_sid))
ORDER BY max_allocated DESC;

-- Get PID

begin
  select pid into :v_pid
  from v$process
  where addr= (select paddr
               FROM   v$session
               WHERE  sid = :v_sid);
end;
/


prompt Dumping 'Other' memory for process:
print v_pid

DECLARE
 mysql VARCHAR2(255);
BEGIN
 mysql := 'alter session set events ''immediate trace name PGA_DETAIL_GET level ' || :v_pid  || '''';
 EXECUTE IMMEDIATE mysql;
END;
/

prompt sleeping 30 seconds
exec dbms_lock.sleep(30)
prompt done

BEGIN
  EXECUTE IMMEDIATE ('drop table temp$tracetable');
EXCEPTION WHEN OTHERS THEN
    IF sqlcode != -942 THEN
      RAISE;
    END IF;
END;
/
DECLARE
 mysql VARCHAR2(255);
BEGIN
  mysql := '
CREATE TABLE temp$tracetable AS
SELECT category, name, heap_name, bytes, allocation_count,
       heap_descriptor, parent_heap_descriptor
FROM   v$process_memory_detail
WHERE  pid      = ' || :v_sid || '
AND    category = ''Other''';
  EXECUTE IMMEDIATE mysql;
END;
/

COLUMN category      HEADING "Category"
COLUMN name          HEADING "Name"
COLUMN heap_name     HEADING "Heap name"
COLUMN q1            HEADING "Memory"  Format 999,999,999,999
SET LINES 150
SELECT * FROM (
   SELECT tab1.category, tab1.name, tab1.heap_name, tab1.bytes q1
   FROM   temp$tracetable tab1
   ORDER BY 4 DESC
   )
WHERE rownum <= 30;

