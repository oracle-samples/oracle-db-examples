DECLARE
  myrowid rowid;
  myclob  clob;
BEGIN
  select rowid into myrowid from foo where rownum = 1;
  dbms_lob.createtemporary( myclob, true );
  fooproc( chartorowid('AAAYNaAAEAAC9WXAAA'),  myclob );
  dbms_output.put_line ( substr( myclob, 1, 255) );
END;
/
