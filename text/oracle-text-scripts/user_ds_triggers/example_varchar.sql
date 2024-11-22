drop table doc
/
drop table doc_mirror
/

create table doc
  (
    rawid       raw(20) primary key ,
    doc_fmt     varchar2(10),
    doc_txt     varchar2(255)
  )
/

create table doc_mirror
  (
    doc_rowid  rowid,
    doc_fmt    varchar2(10),
    dummy      varchar2(1)
  )
/

drop trigger doc_mirror_update
/

create trigger doc_mirror_update
after insert or update on doc
for each row
  begin
    if inserting then
      insert into doc_mirror values 
        (:new.rowid, :new.doc_fmt, 'X');
    else /* updating */
      update doc_mirror m set dummy = dummy
      where m.doc_rowid = :new.rowid;
    end if; 
  end;
/

insert into doc values (
   hextoraw('FF01'), 'BINARY', 'hello world')
/
insert into doc values (
   hextoraw('FF02'), 'TEXT', 'the quick brown fox')
/

select count(*) from doc_mirror
/

-- ctxsys must own the user datastore procedure
-- NOT TRUE IN 11G OR LATER! Must be owned by table owner

connect ctxsys/ctxsys

create or replace procedure sercoproc
  (
    rid  in              rowid,
    tlob in out NOCOPY   clob    /* NOCOPY instructs Oracle to pass
                                    this argument as fast as possible */
  )
is
  tmpbuff varchar2(4000);
begin

  select d.doc_txt into tmpbuff
    from roger.doc d, roger.doc_mirror m
    where d.rowid = m.doc_rowid
    and   m.rowid = rid;

  dbms_lob.write (tlob, length(tmpbuff), 1, tmpbuff);

end;
/

-- list  if inserting then  if inserting then


show errors

grant execute on sercoproc to public
/

connect roger/roger

exec ctx_ddl.drop_preference   ('my_user_ds')
exec ctx_ddl.create_preference ('my_user_ds', 'user_datastore')
exec ctx_ddl.set_attribute     ('my_user_ds', 'PROCEDURE', 'sercoproc')

create index doc_mirror_index on doc_mirror (dummy)
indextype is ctxsys.context
parameters ('datastore my_user_ds')
/

-- check what's in the index
select token_text from dr$doc_mirror_index$i
/

-- test updates 
update doc set doc_txt = 'the quick brown rabbit'
where doc_txt = 'the quick brown fox'
/

exec ctx_ddl.sync_index('doc_mirror_index')

-- check what's in the index
select token_text from dr$doc_mirror_index$i
/

-- this next section tests the user datastore procedure
-- by simulating the calls to it and printing the output

connect roger/roger
Set ServerOutput On
declare
  tlob clob;
  buff varchar2(4000);
  amnt integer;
begin
  for j in
    (
      select rowid from doc_mirror
    )
  loop
    /* this is what the ctx calling env does */
    Dbms_Lob.CreateTemporary
      (
        lob_loc => tlob,
        cache   => true,
        dur     => Dbms_Lob.Session
      );

    ctxsys.sercoproc ( j.rowid, tlob );

    amnt := 4000;
    Dbms_Lob.Read
      (
        lob_loc => tlob,
        amount  => amnt,
        offset  => 1,
        buffer  => buff
      );
    Dbms_Output.Put_Line ( buff );

    /* this is again what the ctx calling env does */
    Dbms_Lob.FreeTemporary
      (
        lob_loc => tlob
      );
  end loop;
end;
/
