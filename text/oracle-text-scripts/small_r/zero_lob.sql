-- zeros a ROWID value in the $R table for a specified DOCID
--
-- You need to know how long your $R rows are (in DOCID lengths)
-- for SMALL_R_ROW this will normally be 35000
-- for original SMALL_R_ROW in 11.2 it will be 70000
-- for non-SMALL_R_ROW it will be 21478365 (~ 21 million) - *I think*
-- check it with SELECT MAX(length(data))/14 FROM DR$indexname$R

-----------------------------------
-- set your index name and $R below
-----------------------------------

define INDEXNAME = myindex2
define ROWSIZE   = 35000

create or replace package dollarr_utils as

  -- rowsize (defined in terms of docid - byte size will be x14)
  ROW_SIZE integer := &ROWSIZE; 

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
  begin

    row    := floor ( (docid-1) / &ROWSIZE );
    offset := ( ( docid - ( row * &ROWSIZE ) ) * 14 ) - 13;

    select data into work from dr$&INDEXNAME$R where row_no = row for update;

    dbms_lob.write(work, 14, offset, buff);

    dbms_output.put_line('Updating row '||row||' pos '||offset);

    update dr$&INDEXNAME$R set data = work where row_no = row;

  end zero_rowid;

end dollarr_utils;
/

show errors;

