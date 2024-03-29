define TAB_NAME=TAB1
define IDX_NAME=TAB1_IDX

declare
  inv_rowid exception;
  pragma exception_init(inv_rowid, -1410);
  testrowid rowid;
  dummy number;
begin
  for c in ( select textkey from dr$&IDX_NAME$k ) loop
    testrowid := c.textkey;
    select count(*) into dummy from &TAB_NAME where rowid = testrowid;
  end loop;
exception
  when inv_rowid then 
     raise_application_error (-20000, 'Failure at rowid ' || testrowid || ' : $K table is corrupt');
end;
/

  
