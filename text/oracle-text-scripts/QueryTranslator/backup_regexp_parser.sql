create or replace package rep is

type wordListType is table of varchar2(64);

function OTSearchString (userStr varchar2, joinChars varchar2 default '') return varchar2;

procedure reParse
  (userStr       in  varchar2, 
   words     out wordListType, 
   joinChars in  varchar2 default '',
   leadChars in  varchar2 default '',
   endChars  in  varchar2 default '');

procedure reParseTest(str varchar2, 
  joinChars varchar2 default '',
  leadChars varchar2 default '',
  endChars  varchar2 default ''
);


end rep;
/
--show err

create or replace package body rep is

-- for debug: just a wrapper round dbms_output.print_line
procedure p (instr varchar2) is
begin
  dbms_output.put_line(instr);
end;

function OTSearchString (userStr varchar2, joinChars varchar2 default '') return varchar2
is 
  plusChar        varchar2(1) := '+';
  minusChar       varchar2(1) := '-';
  wildcard        varchar2(1) := '*';    -- trailing wild card - change if you prefer '%'

  wordlist        wordListType;
  i               integer;
  retStr          varchar2(32767) := '';

  plusList        wordListType := wordListType();
  minusList       wordListType := wordListType();
  ordinList       wordListType := wordListType();

  andStr          varchar2(3) := '';
  accStr          varchar2(3) := '';

begin

  reParse(userStr, wordList, joinChars, plusChar||minusChar, wildcard);

  if wordList is not null and wordList.last > 0 then
    for i in 1..wordList.last() loop

      if substr(wordList(i), 1, 1) = plusChar then
        plusList.extend(1);
        plusList(pluslist.last) := substr(wordList(i), 2, length(wordList(i))-1);
      elsif substr(wordList(i), 1, 1) = minusChar then
        minusList.extend(1);
        minusList(minusList.last) := substr(wordList(i), 2, length(wordList(i))-1);
      else
        ordinList.extend(1);
        ordinList(ordinList.last) := wordList(i);
      end if;

    end loop;

    retStr := retStr || '(';
    if (plusList.count > 0) then
      accStr := ',';                           -- need first acc operator if there's any ands
      retStr := retStr || '(';
      for i in 1..plusList.last loop
        retStr := retStr || andStr || plusList(i);
        andStr := '&';
      end loop;
      retStr := retStr || ')';
    end if;

    if (ordinList.count > 0) then
      for i in 1..ordinList.last loop
        retStr := retStr || accStr || ordinList(i);
        accStr := ',';
      end loop;
    end if;
      
    retStr := retStr || ')';
    if (minusList.count > 0) then
      if length(retStr) = 0 then
         raise_application_error(20000, 'unary NOT not allowed - must have other terms'); 
      end if;
      for i in 1..minusList.last loop
        retStr := retStr || '~' || minusList(i);
      end loop;
    end if;

  else
    return null;
  end if;

  return retStr;  

end;


procedure reParseTest(str varchar2, 
  joinChars varchar2 default '',
  leadChars varchar2 default '',
  endChars  varchar2 default ''
) is
  wordList wordListType;
  i integer;
begin
  reParse(str, wordList, joinChars, leadChars, endChars);
  if wordList is not null and wordList.last > 0 then
    for i in 1..wordList.last() loop
      p(i||': "'||wordList(i)||'"');
    end loop;
  end if;
end;

-- find the first regexp in a string, return string with that 
-- regexp removed, and the match itself

procedure regexp_next_match 
  (str in out varchar2, match out varchar2, pattern varchar2) 
is
  rest    varchar2(32767) := str;
  newstart integer;
begin
     match := regexp_substr(rest, pattern, 1, 1, 'n');
     newStart := regexp_instr(rest, pattern, 1, 1, 1, 'n');
     str := substr(rest, newstart, length(rest)-newstart+1);
end;

-- parse a string into words consisting of alphunumerics, optional join characters
-- and optional single leading and trailing chars. Double quotes surrounding 
-- multiple word will treat them as a single one

procedure reParse 
  (userStr   in  varchar2, 
   words     out wordListType, 
   joinChars in  varchar2 default '',
   leadChars in  varchar2 default '',
   endChars  in  varchar2 default '') 
is
  str       varchar2(32767) := userStr;
  pattern   varchar2(2000);
  match     varchar2(2000);
  i         integer;
  jc        varchar2(128);
  lc        varchar2(128);
  ec        varchar2(128);
begin

  if length(leadChars) > 0  then
    lc := '['||leadChars||']?';
  else
    lc := '';
  end if;

  if length(endChars) > 0 then
    ec := '['||endChars||']?';
  else
    ec := '';
  end if;

  pattern := '(' || lc || '[[:alnum:]' || joinchars || ']+' || ec ||
             ')|(' || lc || '"' || '[[:alnum:]' || joinchars || '][[:alnum:][:space:]' || joinchars || ']+[[:alnum:]' || joinchars || '])"';

  p (pattern);

  words := wordListType();
  while true loop
    regexp_next_match (str, match, pattern);
    match := regexp_replace (match, '^'|| lc || '"(.+)"$', '\1');

    if match is null or length(match) = 0 then
      exit;
    end if;
    words.extend(1);

    words(words.last()) := match;
    p ('Word: <'||match||'>');
    exit when str is null or length(str) = 0;
  end loop;

end;
end rep;
/


/*
dbms_output.put_line('plusList: ');
if (plusList.count > 0) then
  for i in 1..plusList.last loop
    dbms_output.put_line(lpad(i, 3)||': '||plusList(i));
  end loop;
end if;

dbms_output.put_line('minusList: ');
if (minusList.count > 0) then
  for i in 1..minusList.last loop
    dbms_output.put_line(lpad(i, 3)||': '||minusList(i));
  end loop;
end if;

dbms_output.put_line('ordinList: ');
if (ordinList.count > 0) then
  for i in 1..ordinList.last loop
    dbms_output.put_line(lpad(i, 3)||': '||ordinList(i));
  end loop;
end if;
*/
