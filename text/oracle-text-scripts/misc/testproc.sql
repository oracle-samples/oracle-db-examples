Set ServerOutput On
declare
  tlob clob;
  buff varchar2(4000);
  amnt integer;
begin
  for j in
    (
      select rowid from papers
    )
  loop
    /* this is what the ctx calling env does */
    Dbms_Lob.CreateTemporary
      (
        lob_loc => tlob,
        cache   => true,
        dur     => Dbms_Lob.Session
      );

    ctxsys.cdstore$3 ( j.rowid, tlob );

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
