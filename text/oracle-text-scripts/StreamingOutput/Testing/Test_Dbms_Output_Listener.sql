declare
  conn Utl_Tcp.Connection :=
    Utl_Tcp.Open_Connection (
      remote_host => 'localhost',
      remote_port => 1599,
      tx_timeout  => 5,
      newline     => Chr(10));
  dummy pls_integer;
begin
  for j in 1..5 loop
    dummy := Utl_Tcp.Write_Line (conn, j||Lpad (To_Char (Sysdate, 'hh24:mi:ss'), 10));
    Dbms_Lock.Sleep (1);
  end loop;
  Utl_Tcp.Close_Connection (conn);
end Test_Dbms_Output_Listener;
/
