define  PASSWORD   = test2
define  INDEX_NAME = myindex;

drop table tempdocid;
create table tempdocid (docid number);

@insertIntoTempTable.sql

insert into ctxsys.dr$pending
   (pnd_cid,
    pnd_pid,
    pnd_rowid,
    pnd_timestamp,
    pnd_lock_failed)
select 
    cui.idx_id,
    0,
    k.textkey,
    sysdate,
    null
from
    ctx_user_indexes cui,
    tempdocid t,
    dr$&INDEX_NAME$k k
where
    cui.idx_name = upper('&INDEX_NAME')
    and k.docid = t.docid
/
select count(*) "Pending Updates" from ctxsys.dr$pending;

@clearRowid.sql

begin
  for c in ( select docid from tempdocid ) loop
    dollarr_utils.zero_rowid( c.docid );
    begin
      insert into dr$&INDEX_NAME$n (nlt_docid, nlt_mark) values ( c.docid, 'U');
    exception when dup_val_on_index then null;
    end;
end loop;
end;
/

exec ctx_ddl.sync_index('&INDEX_NAME')
