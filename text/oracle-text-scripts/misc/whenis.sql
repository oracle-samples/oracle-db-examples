create or replace procedure whenis (n number) is
  d_stdate  date;
  n_stdate  number;
  n_enddate number;
  d_enddate date;
  s_enddate varchar2(1000);
begin
  d_stdate := to_date('01-JAN-1990', 'DD-MON-YYYY');
  n_stdate := to_number (to_char(d_stdate, 'j'));
  n_enddate := n_stdate + n;
  d_enddate := to_date(n_enddate, 'j');
  s_enddate := to_char(d_enddate, 'DD-MON-YYYY');
  dbms_output.put_line (s_enddate);
end;
/
