declare
  conn Utl_Tcp.Connection :=
    Utl_Tcp.Open_Connection (
      remote_host => 'localhost',
      remote_port => 1599,
      tx_timeout  => 5,
      newline     => Chr(10));
  dummy pls_integer;
begin
  for j in 1..1000 loop
    dummy := Utl_Tcp.Write_Line (conn, Lpad ('a('||Lpad(j,4)||'),', 16));
  end loop;
  Utl_Tcp.Close_Connection (conn);
end;
/
