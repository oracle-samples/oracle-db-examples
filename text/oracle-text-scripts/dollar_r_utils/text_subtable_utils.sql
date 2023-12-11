create or replace package text_subtable_utils as

  procedure zero_rowid (owner varchar2, index_name varchar2, docid number);

end text_subtable_utils;
/
show errors

create or replace package body text_subtable_utils as

procedure zero_rowid (owner varchar2, index_name varchar2, docid number) is
   row    integer;
   offset integer;
   rcount integer;
   rsize  integer;
   buff   raw(14) := hextoraw('0000000000000000000000000000');
   ssql   varchar2(255);
   vindexname  varchar2(30);
   vowner      varchar2(30);
   dummy  varchar2(30);

begin

   if substr(index_name,1,1) = '"' then
      raise_application_error(-20000, 'Quoted index names not currently supported');
   end if;
   if substr(owner,1,1) = '"' then
      raise_application_error(-20000, 'Quoted schema names not currently supported');
   end if;

   dummy := dbms_assert.simple_sql_name(index_name);
   dummy := dbms_assert.simple_sql_name(owner);

   vindexname := upper(index_name);
   vowner     := upper(owner);

   -- check index exists and is not partitioned (todo: support partitioned indexes)

   -- check index exists

   begin
      select idx_id into idxid from ctxsys.ctx_indexes where idx_owner = vowner and idx_name = vindexname;
   exception when no_data_found then
      raise_application_error(-20000, 'index '||vowner||'.'||vindexname||' not found');
   end;

   -- all checks passed. Let's get on with it.

       -- index exists. Is it partitioned?

   select count(*) into partcnt from ctxsys.ctx_index_partitions 
     where ixp_index_owner = vowner and ixp_index_name = vindexname;

   if partcnt > 9999 then 
      -- can't support > 9999 partitions
      raise_application_error(-20000, 'Only 9999 partitions currently allowed');
   end if;

   if partcnt > 0 then
      -- can't support indexnames longer than 20 chars for partitioned index
      if length(vindexname) > 20 then
         raise_application_error(-20000, 'Partitioned index names longer than 20 chars not currently supported');
      end if;
   end if;

    -- determine size pf $R row (SMALL_R_ROW setting)

    ssql := 'select count(*) from DR$'||vindexname||'$R';
    execute immediate ssql into rcount;
    if rcount <= 1 then
      rsize := 200000000;
    else
      ssql := 'select max(length(data)) from DR$'||vindexname||'$R';
      execute immediate ssql into rsize;
    end if;

    row    := floor ( (docid-1) / rsize );
    offset := ( ( docid - ( row * rsize ) ) * 14 ) - 13;

    dbms_output.put_line('rsize = '||rsize || ' Row_no = '||row||' offset = '||offset);
    ssql := 'select data from dr$'||vindexname||'$R where row_no = :row for update';
    execute immediate ssql into work using row;

    dbms_lob.write(work, 14, offset, buff);

    dbms_output.put_line('Updating row '||row||' pos '||offset);

    ssql := 'update dr$'||vindexname||'$R set data = work where row_no = :row';
    execute immediate ssql using row;

    commit;
    
  end zero_rowid;

end text_subtable_utils;
/

show errors;

