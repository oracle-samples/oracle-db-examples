connect / as sysdba
set linesize 150
set trims on
set pagesize 1000
column table_name format a40
column partition_name format a40
column table_owner format a25
column stale_reason format a20
break on table_name

create or replace view example_stale_reason as
select table_name,
       partition_name,
       table_owner,
       mods,
       num_rows,
           case
      when stale_reason_code is null
        then to_char('---')
        else XMLTYPE(replace(DBMS_STATS_INTERNAL.GET_STALE_REASON(stale_reason_code), ' ', '')).extract('/stalenessreason/reason/text()').getstringval()
      end stale_reason
from (
select table_name,
    t.partition_name,
    t.table_owner,
    (v.inserts + v.deletes + v.updates) mods,
    t.num_rows,
    CASE
       WHEN t.last_analyzed IS NULL THEN NULL
       ELSE ( dbms_stats_internal.is_stale(
           o.object_id,
           NULL,
           NULL,
           (v.inserts + v.deletes + v.updates),
           t.num_rows,
           v.flags
           ) )
       END stale_reason_code
from sys.mon_mods_v  v,
     dba_objects     o,
     dba_tab_partitions      t
where v.obj# = o.object_id
and   o.SUBOBJECT_NAME = t.partition_name
and   o.object_name = t.table_name
and   o.owner = t.table_owner);

select * from example_stale_reason order by 3,1,2;
