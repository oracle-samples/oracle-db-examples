-- zeros a ROWID value in the $R table for a specified DOCID
--
----------------------
-- set your index name
----------------------

define INDEXNAME = myindex


create or replace package dollarr_utils as

  procedure zero_rowid (docid number);

end dollarr_utils;
/
show errors

create or replace package body dollarr_utils as

  procedure zero_rowid (docid number) as
    work   blob;
    buff   raw(14) := hextoraw('0000000000000000000000000000');
    row    integer;
    offset integer;
    rcount integer;
    rsize  integer;
  begin

      -- determine size pf $R row (SMALL_R_ROW setting)

    select count(*) into rcount from DR$&INDEXNAME$R;
    if rcount <= 1 then
      rsize := 200000000;
    else 
      select max(length(data)) into rsize from DR$&INDEXNAME$R;
    end if;

    row    := floor ( (docid-1) / rsize );
    offset := ( ( docid - ( row * rsize ) ) * 14 ) - 13;

    dbms_output.put_line('rsize = '||rsize || ' Row_no = '||row||' offset = '||offset);
    select data into work from dr$&INDEXNAME$R where row_no = row for update;

    dbms_lob.write(work, 14, offset, buff);

    dbms_output.put_line('Updating row '||row||' pos '||offset);

    update dr$&INDEXNAME$R set data = work where row_no = row;

  end zero_rowid;

end dollarr_utils;
/

show errors;

