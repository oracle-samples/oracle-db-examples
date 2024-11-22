-- zeros a ROWID value in the $R table for a specified DOCID
-- this would typically be done as a result of finding an invalid ROWID using the
-- associated script dollarRcheck.sql
--
-- Instructions:  First set your index name in the define line below
-- Then run this script as the index owner
-- @clearRowid.sql
-- then execute it for each DOCID where you need the equivalent ROWID to be cleared
-- for example, to clear the ROWID for DOCID number 12345 we would do:
-- exec dollarr_utils.zero_rowid(12345)
-- to clean up afterwards you can optionally run
-- drop packages dollarr_utils

----------------------
-- set your index name
----------------------

define INDEXNAME = myindex

-- set serveroutput on

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

    row    := floor ( (docid-1) * 14 / rsize );
    offset := ( ( docid * 14 - ( row * rsize ) ) ) - 13;

    dbms_output.put_line('docid is ' || docid);
    dbms_output.put_line('rsize = '||rsize || ' Row_no = '||row||' offset = '||offset);
    select data into work from dr$&INDEXNAME$R where row_no = row for update;

    dbms_lob.write(work, 14, offset, buff);

    dbms_output.put_line('Updating row '||row||' pos '||offset);

    update dr$&INDEXNAME$R set data = work where row_no = row;

    commit;
    
end zero_rowid;

end dollarr_utils;
/

show errors;

