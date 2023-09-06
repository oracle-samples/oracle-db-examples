create or replace procedure regexp_clob_next_match
  (str in out clob, match out varchar2, pattern varchar2)
is
  rest    varchar2(32767) := str;
  newstart integer;
begin
     match := regexp_substr(rest, pattern, 1, 1, 'n');
     newStart := regexp_instr(rest, pattern, 1, 1, 1, 'n');
     str := substr(rest, newstart, length(rest)-newstart+1);
end;
/

declare dog clob;
  match varchar2(200);
begin
  dog := 'the quick brown fox jumps';
  loop
    regexp_clob_next_match(dog, match, '[[:alnum:]]+');
    exit when match is null or length(match) = 0;
    dbms_output.put_line(match);
  end loop;
end;
/
