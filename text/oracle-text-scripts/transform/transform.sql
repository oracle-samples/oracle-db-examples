-- this function takes a query string, separates it into words
-- (where a word is a list of alphanumeric characters or underscore)
-- then applies transform strings to each word, and optionally the
-- begining and end of the string
-- for example invoking 
--    mytransform ('the.quick&brown fox', '{', '}', '(', ') within title', 'AND')
-- would return
--    ( {the} AND {quick} AND {brown} AND {fox} ) within title


create or replace function mytransform (
  search   in   varchar2,               /* search string */
  preword  in   varchar2 default '',    /* before each word */ 
  pstword  in   varchar2 default '',    /* after each word */
  beginstr in   varchar2 default '',    /* before whole string */
  endstr   in   varchar2 default '',    /* after whole string */
  operator in   varchar2 default '' )   /* operation between terms */
    return varchar2 is
  qstring varchar2(4000);
  retstr  varchar2(4000) := '';
  type wrdlist is table of varchar2(64);
  words wrdlist;
  prev number;
  separator varchar2(1) := '';
begin
  qstring := search;
  -- initialize table
  words := wrdlist();
  -- replace any special chars in string with spaces
  -- change the regexp here to change the definition of a word
  qstring := regexp_replace(qstring, '[^a-zA-Z0-9_]+', ' ');
  -- replace leading spaces
  qstring := regexp_replace(qstring, '^ *', '');
  -- dbms_output.put_line('QString is '||qstring);
  prev := 1;
  -- loop over string looking for spaces and saving words
  for i in 1..length(qstring) loop
     if substr(qstring, i, 1) = ' ' then
       words.extend(1);
       words(words.last()) := substr(qstring, prev, (i-prev));
       -- dbms_output.put_line('Word "'||words(words.last())||'"');
       prev := i+1;
     end if;
  end loop;
  -- deal with a trailing word after last space
  if prev < length(qstring) then
    words.extend(1);
    words(words.last()) := substr(qstring, prev);
    -- dbms_output.put_line('Word "'||words(words.last())||'"');
  end if;

  -- string parsed, now build the final string
  if length(beginstr) > 0 then
    retstr := beginstr;
    separator := ' ';
  end if;

  for i in 1..words.last() loop

    retstr := retstr || separator || preword || words(i) || pstword;
    if length(operator) > 0 and i < words.last() then
      retstr := retstr || separator || operator;
    end if;
    separator := ' ';

  end loop;
  if length(endstr) > 0 then
    retstr := retstr || separator || endstr;
  end if;
  dbms_output.put_line(retstr);
  return retstr;

end;
/
--list 
--show errors
