CONNECT Sys/telstar AS SYSDBA
alter session set Plsql_Warnings = 'Error:All, Disable:06010'
/
/*
select distinct Authid
from User_Procedures
where Object_Name = 'DBMS_OUTPUT'
and Object_Type = 'PACKAGE'
*/

create or replace package New_DBMS_Output authid Definer is
  type chararr is table of varchar2(32767) index by binary_integer;

  procedure Enable (buffer_size in integer);

  procedure Enable (
    host     varchar2,
    port     binary_integer, -- := 1599,
    charset  varchar2 := null);

  procedure Disable;

  procedure New_Line;
  procedure Put (a varchar2);
  procedure Put_Line (a varchar2);

  procedure Get_Line (line out nocopy varchar2, status out nocopy integer);
  procedure Get_Lines (lines out nocopy chararr, numlines in out nocopy integer);
  procedure Get_Lines (lines out nocopy dbmsoutput_linesarray, numlines in out nocopy integer);
end New_DBMS_Output;
/
SHOW ERRORS

grant execute on New_DBMS_Output to public
/
create or replace public synonym DBMS_Output for sys.New_DBMS_Output
/
create or replace package body New_DBMS_Output is

  utl_tcp_connection Utl_Tcp.Connection;
  disabled       constant pls_integer := 0;
  non_streaming  constant pls_integer := 1;
  streaming      constant pls_integer := 2;
  the_mode       pls_integer := disabled;
  put_buffer     varchar2(32767);

  procedure Enable (buffer_size in integer) is
  begin
    if the_mode = streaming then
      Utl_Tcp.Close_Connection (utl_tcp_connection);
    end if;
    sys.Dbms_Output.Enable (buffer_size=>buffer_size);
    the_mode := non_streaming;
  end Enable;

  procedure Enable (
    host     varchar2,
    port     binary_integer, -- := 1599,
    charset  varchar2 := null) is
  begin
    if the_mode = streaming then
      Utl_Tcp.Close_Connection (utl_tcp_connection);
    end if;
    if charset is null then
      utl_tcp_connection := Utl_Tcp.Open_Connection (
        remote_host => host,
        remote_port => port,
        newline     => Chr(10));
    else
      utl_tcp_connection := Utl_Tcp.Open_Connection (
        remote_host => host,
        remote_port => port,
        newline     => Chr(10),
        charset     => charset);
    end if;
    the_mode := streaming;
    put_buffer := null;
  end Enable;

  procedure Disable is
  begin
    if the_mode = streaming then
      Utl_Tcp.Close_Connection (utl_tcp_connection);
    end if;
    the_mode := disabled;
    sys.Dbms_Output.Disable();
    put_buffer := null;
  end Disable;

  procedure New_Line is
  begin
    case the_mode
      when disabled then
        null;
      when non_streaming then
        sys.Dbms_Output.New_Line();
      when streaming then
        declare dummy pls_integer;
        begin
          if put_buffer is not null then
            dummy := Utl_Tcp.Write_Line (utl_tcp_connection, put_buffer);
          else
            dummy := Utl_Tcp.Write_Line (utl_tcp_connection, Utl_Tcp.crlf);
          end if;
          Utl_Tcp.Flush (utl_tcp_connection);
          put_buffer := null;
        end;
      end case;
  end New_Line;

  procedure Put (a varchar2) is
  begin
    case the_mode
      when disabled then
        null;
      when non_streaming then
        sys.Dbms_Output.Put (a=>a);
      when streaming then
        put_buffer := put_buffer||a;
      end case;
  end Put;

  procedure Put_Line (a varchar2) is
  begin
    case the_mode
      when disabled then
        null;
      when non_streaming then
        sys.Dbms_Output.Put_Line (a=>a);
      when streaming then
        declare dummy pls_integer;
        begin
          dummy := Utl_Tcp.Write_Line (utl_tcp_connection, put_buffer||a);
          Utl_Tcp.Flush (utl_tcp_connection);
          put_buffer := null;
        end;
      end case;
  end Put_Line;

  -- The rest are just wrappers ------------------------------------------------
    procedure Get_Line (line out nocopy varchar2, status out nocopy integer) is
  begin
    sys.Dbms_Output.Get_Line (line=>line, status=>status);
  end Get_Line;

  procedure Get_Lines (lines out nocopy chararr, numlines in out nocopy integer) is
    shipped_lines sys.Dbms_Output.chararr;
  begin
    sys.Dbms_Output.Get_Lines (lines=>shipped_lines, numlines=>numlines);
    if shipped_lines.Count()>0 then
      for j in 1..shipped_lines.Count() loop
        if not shipped_lines.Exists(j) then raise program_error; end if; 
        lines(j) := shipped_lines(j);
      end loop;
    end if;
  end Get_Lines;

  procedure Get_Lines (lines out nocopy dbmsoutput_linesarray, numlines in out nocopy integer) is
  begin
   sys.Dbms_Output.Get_Lines (lines=>lines, numlines=>numlines);
  end Get_Lines;
end New_DBMS_Output;
/
SHOW ERRORS
