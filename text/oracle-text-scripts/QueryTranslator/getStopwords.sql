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

create or replace procedure getStopwords(indexName varchar2) is
  pattern varchar2(255) := 'ctx_ddl\.add_stopword\(''"XXX_SPL"'',''([^'']+)''\)';
  match   varchar2(32767);
  indexScript clob;
  amt number := 240;
  type stopword is  table of varchar2(64);
begin
  dbms_lob.createtemporary(indexScript, true);

  ctx_report.create_index_script(indexName, indexScript, 'XXX');
  dbms_lob.read(indexScript, amt, 240, match);
  dbms_output.put_line(match);
  loop
    regexp_clob_next_match(indexScript, match, pattern);
    exit when match is null or length(match) = 0;
    stopword(1) := (regexp_replace(match, pattern, '\1'));
  end loop;
end;
/


