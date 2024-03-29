create or replace procedure Echo (i in varchar2)
/*
http://localhost:7777/u/Echo?i=Hello
*/
is
begin
  Htp.Print ('
    <HTML>
      <HEAD><TITLE>A Title</TITLE></HEAD>
      <BODY>You said "'||i||'"</BODY>
    </HTML>
  ');
end Echo;
/
--------------------------------------------------------------------------------

create or replace procedure Hello
is
begin
  declare
    n pls_integer := 0;
  begin
    Dbms_Output.Enable ('localhost', 1599, 'WE8ISO8859P1');
    Dbms_Output.Put_Line (Chr(10)||Rpad ('-',30,'-'));
    Dbms_Output.Put_Line ('starting'||Chr(10));
    for j in 1..10 loop    
      Dbms_Output.Put_Line (Lpad (j||' '||To_Char (Sysdate, 'hh24:mi:ss'), 10));
      Dbms_Lock.Sleep (1);
    end loop;
    Dbms_Output.Put_Line (Chr(10)||'Done'||Chr(10));
    Dbms_Output.Disable();
  end;

  Htp.Print ('
    <HTML>
      <HEAD><TITLE>A Title</TITLE></HEAD>
      <BODY>Hello Mod_Plsql 3</BODY>
    </HTML>
  ');
end Hello;
/

--------------------------------------------------------------------------------
-- http://localhost:7777/u/Hello
-- http://localhost:7777/

