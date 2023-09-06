-- Query Parser for Oracle Text

-- Works ONLY with Oracle 10g and later (because it uses the new 
-- regular expression functions)

-- This package takes a query expressed in Google-like syntax, and
-- produces an "unbreakable" Oracle Text query.

-- It is unbreakable because - no matter what the user enters - it
-- will produce a valid query.

-- The ONLY errors you should get are 
--  (1) a possible exception "ORA-20701: too many words in query - query exceeds 4000 chars"
-- This is likely to happen with a OTProgRelax which has more than about 15
-- "simple" terms. 
--  (2) query too complex - caused by over-use of wildcards
-- Hopefully Oracle 10r2 will allow the use of a CLOB as a query string
-- - check back for updates.

-- Query syntax modelled loosely on Google/Alta Vista:
--   +word : word must exist
--   -word : word CANNOT exist
--   "phrase words" : words treated as phrase (may be preceded by + or -)
--   Wild cards % and _ are supported per normal Oracle syntax

-- All other punctuation will be removed, breaking words when appropriate
-- eg. "don't" will be changed to "don t" which is consistent with normal
-- query semantics.

-- Join characters are quoted as necessary. All non-wildcarded words are
-- quoted with braces to avoid keyword problems (eg NT).

-- If query resolves to "unary minus", (eg 'not oracle') then a null string
-- will be returned.

-- Usage: pass the user's query into OTSearchString (simple search) or
-- OTProgRelax (progressive relaxation), together with the index name.
-- Index name is not required, but is strongly recommenended as the processor
-- can then look up join characters and stopwords for that index. If you
-- do not specify the index, you may get expected results (because join 
-- characters have been removed), and longer queries are much more likely
-- to fail because all the stopwords will be included in the query.

-- Note that if there are no query terms, the functions will return NULL STRINGS.
-- it is up to the application to deal with these and raise an appropriate error.

-- OTProgRelax returns a score of type INTEGER by default.
-- You can change this by calling rep.setScoreType(rep.scoreTypeFloat)
-- and set it back with rep.setScoreType(rep.scoreTypeInteger)

-- WARNING: Join characters when indexing should not include any of 
-- the characters: +-"%_ since these are required for the query syntax.
-- The effect of using these join characters is undefined.

-- TODO: dedupe the lists of terms in case of repeating, identical terms
-- (doesn't matter, would just reduce query complexity).

-- Comments? Broken it? Email roger.ford@oracle.com

set define off

create or replace package ubparse is

scoreTypeInteger integer := 0;
scoreTypeFloat   integer := 1;

type wordInfo is record 
   (text varchar2(64), 
    plusWord boolean, 
    minusWord boolean, 
    isPhrase boolean,
    incJoins boolean,
    hasWildcards boolean,
    isStopword boolean);

type wordListType is table of wordInfo;
type wordTableType is table of varchar2(64);  -- simple list of words, eg stoplist

procedure test;
procedure getWords(str in varchar2, words out wordListType, indexName in varchar2 default null);
procedure getJoinChars(indexName varchar2, joinString out varchar2); 
function  OTSimpleSearch (userStr varchar2, indexName varchar2 default '') return varchar2;
function  OTProgRelax (userStr varchar2, indexName varchar2 default '') return varchar2;
procedure SetScoreType (scoreType integer);

end ubparse;
/

create or replace package body ubparse is

global_scoreType varchar2(20) default 'INTEGER';

-- for debug: just a wrapper round dbms_output.print_line
procedure p (instr varchar2) is
begin
  dbms_output.put_line(instr);
end;

procedure test is
  words wordListType;
  str   varchar2(2000);
  q     varchar2(4000);
begin
--  str := 'alongside the great Alexander, King of Kings, were his companions Hepheastion and Piccarus. General Parmenion was his most tragic victim - and this upset Alexander the most';
--  str := '+alexander +the +great';
--  str := '+alexander the great king of kings persian history';
--  str := 'alexander the +great king of kings persian history';
--  str := 'alexander the +"great king" of kings persian history';
--  str := '+alexander "great king" near persi% ';
str := '+alexander +"great k$ng" near dog +k^ngs elephan% persi% ';

  dbms_output.put_line('Raw query is: '||str);

  p ('........10........20........30');
  p ('123456789012345678901234567890');
  p (str);
  p ('.');

/*
  for i in 1..words.last loop
    p ('Text: <'||words(i).text||'>');
    if words(i).plusWord then p('plusWord'); end if;
    if words(i).minusWord then p('minusWord'); end if;
    if words(i).isPhrase then p('isPhrase'); end if;
    if words(i).incJoins then p('incJoins'); end if;
    if words(i).isStopword then p('isStopword'); end if;
  end loop; 
*/
  q := OTSimpleSearch(str, 'ti');
--  q := OTProgRelax(str, 'ti');
--  delete from qlog;
--  insert into qlog values (q);

end;

procedure SetScoreType (scoreType integer)
 is
begin
  if (scoreType = scoreTypeFloat) then
    global_scoreType := 'FLOAT';
  elsif (scoreType = scoreTypeInteger) then
    global_scoreType := 'INTEGER';
  else
    raise_application_error (-20700, 'Invalid score type: use 0 for integer, 1 for float');
  end if;
end;

procedure getStopWords(indexName in varchar2, stopWords in out wordTableType) is
begin
  for c in (select ixv_value from ctx_user_index_values
       where ixv_index_name = upper(indexName)
       and ixv_class = 'STOPLIST'
       and ixv_attribute = 'STOP_WORD') loop
    stopWords.extend(1);
    stopWords(stopWords.last) := c.ixv_value;
  end loop;
end;

-- getJoinChars
-- this procedure builds a regular expression for recognising join characters
-- it's complicated by the fact that in a character class regular expression,
-- any occurence of "]" must be the first entry, "-" must be the last,
-- and "^" must be anything BUT the first.

procedure getJoinChars(indexName varchar2, joinString out varchar2) is 
  printjoins varchar2(2000) := '';
  skipjoins varchar2(2000) := '';
  allJoins varchar2(2000) := '';
  jc1       varchar2(128) := '';        -- special position join chars
  jc2       varchar2(128) := '';
  jc3       varchar2(128) := '';

begin
  begin
    select ixv_value into printjoins
      from ctx_user_index_values 
      where ixv_index_name = upper(indexName)
      and ixv_class= 'LEXER' and ixv_attribute = 'PRINTJOINS';
  exception when no_data_found then null;
  end;
  begin
    select ixv_value into skipjoins
      from ctx_user_index_values 
      where ixv_index_name = upper(indexName)
      and ixv_class= 'LEXER' and ixv_attribute = 'SKIPJOINS';
  exception when no_data_found then null;
  end;
  allJoins := printJoins || skipJoins;
  -- p ('allJoins: '||allJoins);

  if instr (allJoins, ']') > 0 then
    jc1 := ']';
    allJoins := replace (allJoins, ']', '');
  end if;
  if instr (allJoins, '^') > 0 then
    jc2 := '^';
    allJoins := replace (allJoins, '^', '');
  end if;
  if instr (allJoins, '-') > 0 then
    jc3 := '-';
    allJoins := replace (allJoins, '-', '');
  end if;

  if length(jc2) > length(jc1||allJoins||jc3) then   -- ONLY a ^
     joinString := '|\^';
  elsif (jc1 || allJoins || jc2 || jc3) = '^-' then   -- only ^ and -
     joinString := '[-^]';
  else 
    joinString := '[' || jc1 || allJoins || jc2 || jc3 || ']';
    if joinString = '[]' then
      joinString := '';
    end if;
  end if;

end;

-- regexp_next_match
-- return the string representing the next regular expression match
-- of pattern within str
-- the match is REMOVED from the start of str
-- any characters from start of string to start of match are discarded

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

procedure getWords(str in varchar2, words out wordListType, indexName in varchar2 default null) is
  theWords   wordListType    := wordListType();
  stopList   wordTableType   := wordTableType();
  joinString varchar2(2000);               -- join char regexp
  joincat    varchar(1);                   -- "|" or empty if no join chars
  theStr     varchar2(32767) := str;       -- working copy of str 
  pattern    varchar2(2000);
  patt2      varchar2(2000);
  wildcards  varchar2(20)    := '[%_]';
  phrase     varchar2(2000);
  i          integer;
  pos        integer;
begin

  -- if we have an index name, get stopwords and joinchars

  if (indexName is not null and length(indexName) != 0) then
    getStopWords(indexName, stopList);
    getJoinChars(indexName, joinString);
    -- p ('join char regexp: '||joinString);
  end if;

  if joinString is null then 
    joincat := '';
  else
    joincat := '|';
  end if;

  -- build pattern to recognise a word or phrase:

  pattern := '([+-]{0,1}(("([[:space:][:alnum:]]' || joincat || joinString || '|' || wildcards || ')+")|(([[:alnum:]]' || joincat || joinString || '|' || wildcards || '))+))';

  -- p (pattern);

  -- loop through string, collecting words and phrases

  loop
    regexp_next_match(theStr, phrase, pattern);
    exit when phrase is null or length(phrase) = 0;
    -- p ('Phrase: <'||phrase||'>');

    -- remove leading and trailing spaces

    phrase := regexp_replace(phrase, '^ ');
    phrase := regexp_replace(phrase, ' $');

    -- We've got a word or phrase but it may still have +- in front, and may be in quotes

    theWords.extend(1);

    if substr(phrase, 1, 1) = '+' then
      theWords(theWords.last).plusWord := TRUE;
      phrase := substr(phrase, 2, length(phrase)-1);
    else
      theWords(theWords.last).plusWord := FALSE;
    end if;              

    if substr(phrase, 1, 1) = '-' then
      theWords(theWords.last).minusWord := TRUE;
      phrase := substr(phrase, 2, length(phrase)-1);
    else
      theWords(theWords.last).minusWord := FALSE;
    end if;              

    if substr(phrase, 1, 1) = '"' then
      theWords(theWords.last).isPhrase := TRUE;
      phrase := substr(phrase, 2, length(phrase)-2);
    else
      theWords(theWords.last).isPhrase := FALSE;
    end if;              

    if regexp_instr(phrase, wildcards) > 0 then
      theWords(theWords.last).hasWildcards := TRUE;
    else
      theWords(theWords.last).hasWildcards := FALSE;
    end if;

    theWords(theWords.last).isStopword := FALSE;      
    if stopList.last > 0 then
      for i in 1..stopList.last loop
        if phrase = stopList(i) then
           theWords(theWords.last).isStopword := TRUE;
           exit when true;
        end if;
      end loop;
    end if;

    -- if the query is a phrase and includes wildcards, we must quote everything EXCEPT
    -- the wildcarded words. Otherwise, if there ARE wildcards, don't quote it, if
    -- there are, then do.
   
    if theWords(theWords.last).hasWildcards then
      if theWords(theWords.last).isPhrase then

        patt2 := '(^| )(([[:alnum:]]' || joincat || joinString || ')+)( |$)';
        pos := 1;
        pos := regexp_instr(phrase, patt2);
        while pos > 0 loop
           phrase := regexp_replace(phrase, patt2, '{\2}', pos);
           pos := regexp_instr(phrase, patt2, pos+3);  -- next char but we've inserted two
        end loop;
      end if;
    else
      phrase := '{' || phrase || '}';
    end if;

    theWords(theWords.last).text := phrase;

    words := theWords;

  end loop;

end;

-- Simple search: produce a simple search string
-- Actually it's not all that simple, because of the scoring requirements.
-- We need to make sure all + words are there, but score on the total words
-- present, for which we'll use ACCUM (the "," operator).
--
-- Here's a list of sample transformations:
--
--  Input Qry    CONTEXT Syntax Output Qry
--  ---------    ---------------------------------
--  +a b         ((a)*10*10) & (a , b)
--  a b          (a , b)
--  +a +b c d    ((a & b)*10*10) & (a , b , c , d)
--- +a +b        ((a & b)*10*10) & (a , b)

function OTSimpleSearch (userStr varchar2, indexName varchar2 default '') return varchar2
is

  wordlist        wordListType;
  i               integer;
  retStr          varchar2(4000) := '';

  plusList        wordListType := wordListType();
  minusList       wordListType := wordListType();
  ordinList       wordListType := wordListType();

  andStr          varchar2(3) := '';
  accStr          varchar2(3) := '';

begin

  getWords(userStr, wordList, indexName);

  if wordList is not null and wordList.last > 0 then
    for i in 1..wordList.last() loop

      if wordlist(i).plusWord and not wordlist(i).isStopword then
        plusList.extend(1);
        plusList(pluslist.last) := wordList(i);
      elsif wordList(i).minusWord and not wordList(i).isStopword then
        minusList.extend(1);
        minusList(minusList.last) := wordList(i);
      elsif not wordList(i).isStopword then
        ordinList.extend(1);
        ordinList(ordinList.last) := wordList(i);
      end if;
    end loop;

    -- Check for "unary not" - only minus terms. Return a null string in this case.

    if (minusList.last > 0) then
      if (plusList.last > 0 or ordinList.last > 0) then
         null;
      else
         -- put back line below if you prefer an error for "minus only" searches
         -- raise_application_error(-20700, 'unary NOT is not allowed: you must have other terms'); 
         return NULL;
      end if;
    end if;

    -- Required (plus) words

    if (plusList.count > 0) then
      retStr := retStr || '(';
      retStr := retStr || '(';
      for i in 1..plusList.last loop
        retStr := retStr || andStr || plusList(i).text;
        andStr := '&';
      end loop;
      retStr := retStr || ')*10*10)';
    end if;

    retStr := retStr || andStr || '(';   -- (andStr will be empty if no pluswords)

    -- All words : need pluswords as well as normal words for scoring

    if (plusList.count > 0) then
      for i in 1..plusList.last loop
        retStr := retStr || accStr || plusList(i).text;
        accStr := ',';
      end loop;
    end if;
    if (ordinList.count > 0) then
      for i in 1..ordinList.last loop
        retStr := retStr || accStr || ordinList(i).text;
        accStr := ',';
      end loop;
    end if;
      
    retStr := retStr || ')';
    if (minusList.count > 0) then
      for i in 1..minusList.last loop
        retStr := retStr || '~' || minusList(i).text;
      end loop;
    end if;

  else
    return null;
  end if;

  return retStr;  

  exception
      when value_error then
         raise_application_error(-20701, 'too many words in query - translated query exceeds 4000 chars');

end;

function OTProgRelax (userStr varchar2, indexName varchar2 default '') return varchar2
is 
  wordlist        wordListType;
  i               integer;
  k               integer;
  retStr          varchar2(4000) := '';

  plusList        wordListType := wordListType();
  minusList       wordListType := wordListType();
  ordinList       wordListType := wordListType();
  allList         wordListType := wordListType();
  tList           wordListType;

  andStr          varchar2(3) := '';
  accStr          varchar2(3) := '';

begin

  getWords(userStr, wordList, indexName);

  if wordList is not null and wordList.last > 0 then
    for i in 1..wordList.last() loop

      if wordlist(i).plusWord then
        plusList.extend(1);
        plusList(pluslist.last) := wordList(i);
        allList.extend(1);
        allList(alllist.last) := wordList(i);
      elsif wordList(i).minusWord then
        minusList.extend(1);
        minusList(minusList.last) := wordList(i);
      else
        ordinList.extend(1);      accStr := ',';                           -- need first acc operator if there's any ands
        ordinList(ordinList.last) := wordList(i);
        allList.extend(1);
        allList(allList.last) := wordList(i);
      end if;

    end loop;      

    -- Check for "unary not" - only minus terms. If we have this then we'll change
    -- all the minus terms to ordinary terms to avoid causing an error.

    if (minusList.last > 0) then
      if (allList.last > 0) then
         null;
      else
         -- put back line below if you prefer an error for "minus only" searches
         -- raise_application_error(-20700, 'unary NOT is not allowed: you must have other terms'); 
         return NULL;
      end if;
    end if;

    retStr := '<query><textquery><progression>';

    ----------------------------------------------------
    -- PROGRESSION STEP 1: All words together as phrase
    ----------------------------------------------------

    andStr := '';
    retStr := retStr || chr(10)||'<seq>(';
    for i in 1..allList.last loop
      retStr := retStr || andStr || allList(i).text;
      andStr := ' ';
    end loop;
    retStr := retStr || ')';

    -- deal with notAllowed words
    if minusList.last > 0 then
      for i in 1..minusList.last loop
        retStr := retStr || '~' || minusList(i).text;
      end loop;
    end if;
    retStr := retStr || '</seq>';

    -------------------------------------------------------------------
    -- Stopwords are needed only during the first step, remove them now

    tList := wordListType();
    if plusList.count > 0 then
      for i in 1..plusList.last loop
        if not plusList(i).isStopword then
          tList.extend(1);
          tList(tList.last) := plusList(i);
        end if;
      end loop;
      plusList := tList;
    end if;

    tList.trim(tList.count);
    if minusList.count > 0 then
      for i in 1..minusList.last loop
        if not minusList(i).isStopword then
          tList.extend(1);
          tList(tList.last) := minusList(i);
        end if;
      end loop;
      minusList := tList;
    end if;

    tList.trim(tList.count);
    if allList.count > 0 then
      for i in 1..allList.last loop
        if (not (allList(i).isStopword)) then
          tList.extend(1);
          tList(tList.last) := allList(i);
        end if;
      end loop;
      allList := tList;
    end if;

    if ordinList.count > 0 then
      tList.trim(tList.count);
      for i in 1..ordinList.last loop
        if not ordinList(i).isStopword then
          tList.extend(1);
          tList(tList.last) := ordinList(i);
        end if;
      end loop;
      ordinList := tList;
    end if;

    -- completed removal of stopwords
    ---------------------------------

    if allList.count > 1 then
      
      ----------------------------------------------------------------
      -- PROGRESSION STEP 2: All words present and close to each other
      ----------------------------------------------------------------

      andStr := '';
      retStr := retStr || chr(10)||'<seq>( NEAR((';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i).text;
        andStr := ',';
      end loop;
      retStr := retStr || ')) )';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i).text;
        end loop;
      end if;
      retStr := retStr || '</seq>';

      -----------------------------------------------------------------
      -- PROGRESSION STEP 3: ALL words present, some near to each other
      -----------------------------------------------------------------

      andStr := '';
      retStr := retStr || chr(10)||'<seq>((';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i).text;
        andStr := '&';
      end loop;
      retStr := retStr || ')*10*10';

      andStr := '';
      retStr := retStr || ')&(';

      for i in 1..allList.last loop
        for k in i+1..(allList.last) loop
          if i != k then
            retStr := retStr || andStr || 'NEAR(('||allList(i).text||','||allList(k).text||'))';
            andStr := ',';
          end if;
        end loop;
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i).text;
        end loop;
      end if;
      retStr := retStr || '</seq>';

      ---------------------------------------------------------
      -- PROGRESSION STEP 4: ALL words present, anywhere in doc
      ---------------------------------------------------------

      andStr := '';
      retStr := retStr || chr(10)||'<seq>(';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i).text;
        andStr := '&';
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i).text;
        end loop;
      end if;
      retStr := retStr || '</seq>';

      ----------------------------------------------------------
      -- PROGRESSION STEP 5: Some words present, near each other
      ----------------------------------------------------------

      andStr := '';
      retStr := retStr || chr(10)||'<seq>';

      if plusList.last > 0 then
        retStr := retStr || '((';
        for i in 1..plusList.last loop
          retStr := retStr || andStr || plusList(i).text;
          andStr := '&';
        end loop;
        retStr := retStr || ')*10*10)';
      end if;

      if plusList.last > 0 then
        retStr := retStr || '&';
      end if;
      retStr := retStr || '(';

      andStr := '';

      for i in 1..allList.last loop
        for k in i+1..(allList.last) loop
          if i != k then
            retStr := retStr || andStr || 'NEAR(('||allList(i).text||','||allList(k).text||'))';
            andStr := ',';
          end if;
        end loop;
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i).text;
        end loop;
      end if;
      retStr := retStr || '</seq>';

    end if;

    -----------------------------------------
    -- PROGRESSION STEP 6: Some words present
    -----------------------------------------

    -- END OF STEPS    

    retStr := retStr || chr(10) || '</progression></textquery><score datatype="'
              ||global_scoreType||'"/></query>';

  else
    return null;
  end if;

  return retStr;  

  exception
      when value_error then
         raise_application_error(-20701, 'too many words in query - translated query exceeds 4000 chars');
end;

end ubparse;
/
show err

