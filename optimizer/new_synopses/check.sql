--
-- List synopsis types per partition
-- There is an Enhancement Request to include
-- this information in data dictionary views.
--
column partition_name format a40
column synopsis_type format a40
set pagesize 1000
set linesize 500
set trims on
set tab off

select subobject_name                                          partition_name, 
       decode(h.spare1,NULL,'ADAPTIVE SAMPLING','HYPERLOGLOG') synopsis_type
from   dba_objects o,
       sys.wri$_optstat_synopsis_head$ h
where  o.object_type = 'TABLE PARTITION'
and    o.object_name = UPPER('&table_name')
and    o.owner       = USER
and    h.group#      = o.object_id*2
and    intcol#       = 1
order by partition_name;

