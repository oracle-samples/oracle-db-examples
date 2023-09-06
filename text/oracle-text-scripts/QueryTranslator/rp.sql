create or replace procedure rp (instr varchar2) is 

  rest    varchar2(32767) := instr;
  ctoken  varchar2(32767);
  pattern varchar2(2000);
  newstart integer;

begin

  while true loop
     pattern := '[[:alnum:]]+';
     ctoken := regexp_substr(rest, pattern, 1, 1, 'n');
     p ('"'||ctoken||'"');
     newStart := regexp_instr(rest, pattern, 1, 1, 1, 'n');
     exit when (length(rest)-newStart) <= 0;
     rest := substr(rest, newstart, length(rest)-newstart+1);
     p ('rest: '||rest);
  end loop;
end;
/


