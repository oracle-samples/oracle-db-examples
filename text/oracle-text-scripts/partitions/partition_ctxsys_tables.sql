connect / as sysdba

alter user ctxsys identified by tmppassword1764 account unlock;

grant create table to ctxsys;

connect ctxsys/tmppassword1764;

create or replace procedure partition_ctxsys_tables authid definer
is
  num_partitions number;
  tmp_partitions number;
  cur_partitions number;
  pt_ok boolean := FALSE;
  dt_ok boolean := FALSE;
begin

  execute immediate
    'lock table dr$pending in exclusive mode';

  execute immediate
    'lock table dr$delete in exclusive mode';

  -- how many partitions should we have
  select count(1) into num_partitions from dr$index
    where instr(idx_option, 'O')=0 and
          instr(idx_option, 'E')=0;

  select count(1) into tmp_partitions from dr$index_partition;
  num_partitions := num_partitions + tmp_partitions;

 if num_partitions < 100 then
    num_partitions := 100;
  else
    num_partitions := num_partitions*2;
  end if;

  execute immediate
    'create table dr$pending_partitioned (
      pnd_cid           number NOT NULL,
      pnd_pid           number  default 0 NOT NULL,
      pnd_rowid         rowid NOT NULL,
      pnd_timestamp     date,
      pnd_lock_failed   char(1) default ' || '''N''' || ',
      primary key (pnd_cid, pnd_pid, pnd_rowid)
    )
    organization index
    partition by hash(pnd_cid, pnd_pid)
    partitions ' || num_partitions ||
    ' enable row movement
    storage (freelists 10)';

    pt_ok := TRUE;

    execute immediate
      'insert /*+ APPEND */into dr$pending_partitioned 
        select * from dr$pending';

    commit;

    execute immediate
      'drop table dr$pending';

    execute immediate
      'alter table dr$pending_partitioned rename to dr$pending';

    execute immediate
     'create table dr$delete_partitioned (
      del_idx_id    number,
      del_ixp_id    number,
      del_docid     number,
      constraint drc$del_key_part primary key (del_idx_id, del_ixp_id,
       del_docid)
    )
    organization index
    partition by hash(del_idx_id, del_ixp_id)
    partitions ' || num_partitions ||
    ' enable row movement
    storage (freelists 10)';

    dt_ok := TRUE;

    execute immediate
      'insert /*+ APPEND */ into dr$delete_partitioned 
         select * from dr$delete';

    commit;

    execute immediate
      'drop table dr$delete';

    execute immediate
      'alter table dr$delete_partitioned rename to dr$delete';

    execute immediate
      'alter table dr$delete rename constraint drc$del_key_part to drc$del_key';
    execute immediate
      'alter index drc$del_key_part rename to drc$del_key';

    commit;

END partition_ctxsys_tables;

/

execute partition_ctxsys_tables

connect / as sysdba

alter user ctxsys account lock;
