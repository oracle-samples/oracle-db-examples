-- Regular Expression Parser for Oracle Text
-- Take any user input and produce a sensible Oracle Text query.

-- This package uses Oracle regular expressions to produce
-- an "unbreakable" query parser - that is, it should produce a valid
-- Oracle Text query regardless of what the user enters

-- Possible errors:
-- ORA-20701: too many words in query - query exceeds 4000 chars
-- This is likely to happen with a OTProgRelax which has more than about 15
-- "simple" terms. If this happens you should be using the CLOB version 
-- OTProgRelaxClob, and a CLOB bind variable.

-- Query syntax modelled loosely on Google/Alta Vista:
--   word : score will be improved if word exists
--   +word : word must exist
--   -word : word CANNOT exist
--   "phrase words" : words treated as phrase (may be preceded by + or -)
--   a word consists of a sequence of alphanumerics and join characters
--   trailing wild cards ONLY are supported: eg oracl* - default char is *
--   no wild cards in phrases

-- NOTE: unfortunately you can't do 
--  ... CONTAINS (col, OTProgRelax(:userQuery) > 0;

-- All other punctuation will be removed, breaking words when appropriate
-- eg. "don't" will be changed to "don t" which is consistent with normal
-- query semantics.

-- Join characters are quoted as necessary. All non-wildcarded words are
-- quoted with braces to avoid keyword problems (eg NT).

-- If query resolves to "unary minus", (eg 'not oracle') then a null string
-- will be returned.

-- Usage: pass the user's query into OTSearchString (simple search) or
-- OTProgRelax (progressive relaxation)
-- OTSearchString takes an optional list of  join characters 
-- (which MUST be the same as used by the index).
-- Note that PRINTJOINS and SKIPJOINS should both be passed in - there is
-- no need for a distinction here as the internal query parser will deal with
-- removing SKIPJOINS.
-- OTProgRelax takes an optional index name. If the index name is specified,
-- OTPorgRelax will find the join characters and stopwords used in the index.

-- Note that if there are no query terms, the functions will return NULL STRINGS.
-- it is up to the application to deal with these and raise an appropriate error.

-- OTProgRelax returns a score of type INTEGER by default.
-- You can change this by calling rep.setScoreType(rep.scoreTypeFloat)
-- and set it back with rep.setScoreType(rep.scoreTypeInteger)
-- This is recommended when using OTProgRelax, since the many options really
-- require fine-grained scoring to distinguish between them.

-- If you want to use the NEAR2 operator rather than NEAR (NEAR2 is an undocumented
-- feature in 11.2) use 
-- rep.UseNEAR2(rep.optionTrue)

-- A note on stopwords: OTProgRelax wants to know your index name, and extracts
-- the stopwords. It ONLY uses stopwords when doing the "combo near" part of the query. 
-- Since this part of the query searches for all NEAR pairs, it expands exponentially
-- as the number of words increases. Removing stopwords here is a significant benefit
-- Elsewhere it doesn't make much difference.

-- TODO: dedupe the lists of terms in case of repeating, identical terms
-- (doesn't matter, would just reduce query complexity).
-- TODO: when using NEAR2, we can simplify the prog relax query since we don't need
-- all the NEAR operations on pairs of terms.

-- LIMITATIONS: This is designed for space-separated languages and is unlikely to
-- produce good results with Chinese, Japanese, Korean, etc.

-- MAY NOT WORK FULLY with:
--    AUTO_LEXER
--    MULTI_LEXER

-- Comments?  Send them to roger.ford@oracle.com


create or replace package rep is

type wordListType is table of varchar2(64);

scoreTypeInteger integer := 0;
scoreTypeFloat   integer := 1;

optionFalse       integer := 0;
optionTrue        integer := 1;

procedure SetScoreType (scoreType integer);
procedure UseNEAR2     (near2Option integer);
procedure SetWildcard  (wildcard varchar2);

-- OTSearchString returns a simple search string which can be plugged into a CONTAINS clause
-- It comes in two versions, one returning a VARCHAR2 and one returning a CLOB

function OTSearchString     (userStr varchar2, joinChars varchar2 default '') return varchar2;
function OTSearchStringClob (userStr varchar2, joinChars varchar2 default '') return clob;

-- OTProgRelax returns a more complex value using Progressive Relaxation which does the following:
--   Phrase Search (all words together, in order) 
--   Near Search (all words near each other)
--   AND search (all words anywhere in the document)
--   ACCUM search (any words, scoring higher depending on how many words are present)
-- It comes in two versions, one returning a VARCHAR2 and one returning a CLOB

function OTProgRelax     (userStr varchar2, indexName varchar2 default '') return varchar2;
function OTProgRelaxClob (userStr varchar2, indexName varchar2 default '') return clob;

procedure reParse
  (userStr       in  varchar2, 
   words     out wordListType, 
   joinChars in  varchar2 default '',
   leadChars in  varchar2 default '',
   userWild  in  varchar2 default '*',
   sysWild   in  varchar2 default '%');

procedure reParseTest(str varchar2, 
  joinChars varchar2 default '',
  leadChars varchar2 default '',
  endChars  varchar2 default ''
);

end rep;
/
show err

create or replace package body rep is

-- Global variables settable by SetXXX procedures

global_scoreType varchar2(20) default 'INTEGER';
global_nearOper  varchar2(5)  default 'NEAR';
global_wildCard  varchar2(1)  default '*';

-- for debug: just a wrapper round dbms_output.print_line
procedure p (instr varchar2) is
begin
  dbms_output.put_line(instr);
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

-- Similar to above but for clobs

procedure regexp_clob_next_match
  (str in out clob, match out varchar2, pattern varchar2)
is
  rest    varchar2(32767) := str;
  newstart integer;
begin
     match := regexp_substr(rest, pattern, 1, 1, 'n');
     newStart := regexp_instr(rest, pattern, 1, 1, 1, 'n');
     str := substr(rest, newstart, length(rest)-newstart+1);
end;

-- find stopwords for a particular index (via ctx_report)
-- expects to received an initialized table for stopWords

procedure getStopWords(indexName in varchar2, stopWords in out wordListType) is
  type stopword is table of varchar2(64);
begin
  for c in (select ixv_value from ctx_user_index_values
       where ixv_index_name = upper(indexName)
       and ixv_class = 'STOPLIST'
       and ixv_attribute = 'STOP_WORD') loop
    stopWords.extend(1);
    stopWords(stopWords.last) := c.ixv_value;
  end loop;
end;

procedure getJoinChars(indexName in varchar2, joinChars in out varchar2) is
begin
  joinChars := '';
  for c in (select ixv_value from ctx_user_index_values
       where ixv_index_name = upper(indexName)
       and ixv_class = 'LEXER'
       and ( ixv_attribute = 'PRINTJOINS'
          or ixv_attribute = 'SKIPJOINS' ) ) loop
    joinChars := joinChars || c.ixv_value;
  end loop;
end;

-- Check whether word is in stopword list

function notStopWord (testWord varchar2, stopList wordListType) return boolean is
  i integer;
  w varchar2(256);
begin
  -- strip any braces
  w := testWord;
  w := replace(w, '{', '');
  w := replace(w, '}', '');

  if stopList.count = 0 then
    return true;
  end if;
  for i in 1 .. stopList.last loop
    --p('comparing '''|| w ||''' against '''||stopList(i)||'''');
    if lower(w) = lower(stopList(i)) then
      return false;
    end if;
  end loop;
  return true;
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

procedure UseNEAR2     (near2Option integer)
 is
begin
  if (near2Option = optionTrue) then 
    global_nearOper := 'NEAR2';
  elsif (near2Option = optionFalse) then
    global_nearOper := 'NEAR';
  else
    raise_application_error (-20700, 'Invalid NEAR2 option: use 0 for NEAR, 1 for NEAR2');
  end if;
end;

procedure SetWildCard (wildcard varchar2)
 is
begin
  if (wildcard = '%') then
    global_wildcard := wildcard;
  elsif (wildcard = '*') then
    global_wildcard := wildcard;
  else
    raise_application_error (-20700, 'Invalid wildcard: must be ''%'' or ''*''');
  end if;
end;

function OTSearchString (userStr varchar2, joinChars varchar2 default '') return varchar2
is 
  plusChar        varchar2(1)    := '+';
  minusChar       varchar2(1)    := '-';
  wildcard        varchar2(1)    := global_wildcard;

  wordlist        wordListType;
  i               integer;
  retStr          varchar2(4000) := '';

  plusList        wordListType   := wordListType();
  minusList       wordListType   := wordListType();
  ordinList       wordListType   := wordListType();

  andStr          varchar2(3)    := '';
  accStr          varchar2(3)    := '';

begin

  -- p('calling reParse with string '||userStr);
  reParse(userStr, wordList, joinChars, plusChar||minusChar, wildcard, '%');

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
      for i in 1..minusList.last loop
        retStr := retStr || '~' || minusList(i);
      end loop;
    end if;

  else
    return null;
  end if;

  return retStr;  

  exception
      when value_error then
         raise_application_error(-20701, 'too many words in query - translated query exceeds 4000 chars');

end OTSearchString;

-- Same as previous function but returns a CLOB

function OTSearchStringClob (userStr varchar2, joinChars varchar2 default '') return clob
is 
  plusChar        varchar2(1)  := '+';
  minusChar       varchar2(1)  := '-';
  wildcard        varchar2(1)  := global_wildcard;

  wordlist        wordListType;
  i               integer;
  retStr          clob         := '';

  plusList        wordListType := wordListType();
  minusList       wordListType := wordListType();
  ordinList       wordListType := wordListType();

  andStr          varchar2(3)  := '';
  accStr          varchar2(3)  := '';

begin

  -- p('calling reParse with string '||userStr);
  reParse(userStr, wordList, joinChars, plusChar||minusChar, wildcard, '%');

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
      for i in 1..minusList.last loop
        retStr := retStr || '~' || minusList(i);
      end loop;
    end if;

  else
    return null;
  end if;

  return retStr;  

  exception
      when value_error then
         raise_application_error(-20701, 'too many words in query - translated query exceeds 4000 chars');

end OTSearchStringClob;

function OTProgRelax (userStr varchar2, indexName varchar2 default '') return varchar2
is 
  plusChar        varchar2(1)  := '+';
  minusChar       varchar2(1)  := '-';
  wildcard        varchar2(1)  := global_wildcard;    -- trailing wild card - change if you prefer '%'

  wordlist        wordListType;
  i               integer;
  k               integer;
  retStr          varchar2(4000) := '';

  plusList        wordListType := wordListType();
  minusList       wordListType := wordListType();
  ordinList       wordListType := wordListType();
  allList         wordListType := wordListType();
  stopList        wordListType := wordListType();

  joinChars       varchar2(255):= '';
  andStr          varchar2(3)  := '';
  accStr          varchar2(3)  := '';

begin

  if indexName is not null and length(indexName) > 0 then
     getStopWords(indexName, stopList);
     getJoinChars(indexName, joinChars);
  end if;

  reParse(userStr, wordList, joinChars, plusChar||minusChar, wildcard, '%');

  if wordList is not null and wordList.last > 0 then
    for i in 1..wordList.last() loop

      if substr(wordList(i), 1, 1) = plusChar then
        plusList.extend(1);
        plusList(pluslist.last) := substr(wordList(i), 2, length(wordList(i))-1);
        allList.extend(1);
        allList(alllist.last) := substr(wordList(i), 2, length(wordList(i))-1);
      elsif substr(wordList(i), 1, 1) = minusChar then
        minusList.extend(1);
        minusList(minusList.last) := substr(wordList(i), 2, length(wordList(i))-1);
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

    -- STEP 1: All words together as phrase

    andStr := '';
    retStr := retStr || chr(10)||'<seq>(';
    for i in 1..allList.last loop
      retStr := retStr || andStr || allList(i);
      andStr := ' ';
    end loop;
    retStr := retStr || ')';

    -- deal with notAllowed words
    if minusList.last > 0 then
      for i in 1..minusList.last loop
        retStr := retStr || '~' || minusList(i);
      end loop;
    end if;
    retStr := retStr || '</seq>';

    if allList.count > 1 then
      
      -- STEP 2: All words present and close to each other

      andStr := '';
      retStr := retStr || chr(10)||'<seq>( '||global_nearOper||'((';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i);
        andStr := ',';
      end loop;
      retStr := retStr || ')) )';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i);
        end loop;
      end if;
      retStr := retStr || '</seq>';

      -- STEP 3: ALL words present, some near to each other

      andStr := '';
      retStr := retStr || chr(10)||'<seq>((';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i);
        andStr := '&';
      end loop;
      retStr := retStr || ')*10*10';

      andStr := '';
      retStr := retStr || ')&(';
      for i in 1..allList.last loop
        for k in i+1..(allList.last) loop
          if i != k then
            if notStopWord(allList(i), stopList) and notStopWord(allList(k), stopList) then 
              retStr := retStr || andStr || ''||global_nearOper||'(('||allList(i)||','||allList(k)||'))';
              andStr := '&';
            end if;
          end if;
        end loop;
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i);
        end loop;
      end if;
      retStr := retStr || '</seq>';

      -- STEP 4: ALL words present, anywhere in doc

      andStr := '';
      retStr := retStr || chr(10)||'<seq>(';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i);
        andStr := '&';
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i);
        end loop;
      end if;
      retStr := retStr || '</seq>';

      -- STEP 5: Some words present

      andStr := '';
      retStr := retStr || chr(10)||'<seq>';

      if plusList.last > 0 then
        retStr := retStr || '((';
        for i in 1..plusList.last loop
          retStr := retStr || andStr || plusList(i);
          andStr := '&';
        end loop;
        retStr := retStr || ')*10*10)';
      end if;

      andStr := '';
      if plusList.last > 0 then
        retStr := retStr || '&';
      end if;
      retStr := retStr || '(';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i);
        andStr := ',';
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i);
        end loop;
      end if;
      retStr := retStr || '</seq>';

    end if;

    -- END OF STEPS    

    retStr := retStr || chr(10) || '</progression></textquery><score datatype="'||global_scoreType||'"/></query>';

  else
    return null;
  end if;

  return retStr;  

  exception
      when value_error then
         raise_application_error(-20701, 'too many words in query - translated query exceeds 4000 chars');
end OTProgRelax;

-- Same as previous function, but returning CLOB rather than VARCHAR2

function OTProgRelaxClob (userStr varchar2, indexName varchar2 default '') return clob
is 
  plusChar        varchar2(1)  := '+';
  minusChar       varchar2(1)  := '-';
  wildcard        varchar2(1)  := global_wildcard;    -- trailing wild card - change if you prefer '%'

  wordlist        wordListType;
  i               integer;
  k               integer;
  retStr          clob         := '';

  plusList        wordListType := wordListType();
  minusList       wordListType := wordListType();
  ordinList       wordListType := wordListType();
  allList         wordListType := wordListType();
  stopList        wordListType := wordListType();


  joinChars       varchar2(255):= '';
  andStr          varchar2(3)  := '';
  accStr          varchar2(3)  := '';

begin

  if indexName is not null and length(indexName) > 0 then
     getStopWords(indexName, stopList);
     getJoinChars(indexName, joinChars);
  end if;

  reParse(userStr, wordList, joinChars, plusChar||minusChar, wildcard, '%');

  if wordList is not null and wordList.last > 0 then
    for i in 1..wordList.last() loop

      if substr(wordList(i), 1, 1) = plusChar then
        plusList.extend(1);
        plusList(pluslist.last) := substr(wordList(i), 2, length(wordList(i))-1);
        allList.extend(1);
        allList(alllist.last) := substr(wordList(i), 2, length(wordList(i))-1);
      elsif substr(wordList(i), 1, 1) = minusChar then
        minusList.extend(1);
        minusList(minusList.last) := substr(wordList(i), 2, length(wordList(i))-1);
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

    retStr := '<query>
  <textquery>
    <progression>';

    -- STEP 1: All words together as phrase

    andStr := '';
    retStr := retStr || chr(10)||'      <seq>(';
    for i in 1..allList.last loop
      retStr := retStr || andStr || allList(i);
      andStr := ' ';
    end loop;
    retStr := retStr || ')';

    -- deal with notAllowed words
    if minusList.last > 0 then
      for i in 1..minusList.last loop
        retStr := retStr || '~' || minusList(i);
      end loop;
    end if;
    retStr := retStr || '</seq>';

    if allList.count > 1 then
      
      -- STEP 2: All words present and close to each other

      andStr := '';
      retStr := retStr || chr(10)||'      <seq>( ' ||global_nearOper|| '((';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i);
        andStr := ',';
      end loop;
      retStr := retStr || ')) )';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i);
        end loop;
      end if;
      retStr := retStr || '</seq>';

      -- STEP 3: ALL words present, some near to each other

      andStr := '';
      retStr := retStr || chr(10)||'      <seq>((';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i);
        andStr := '&';
      end loop;
      retStr := retStr || ')*10*10';

      andStr := '';
      retStr := retStr || ')&(';
      for i in 1..allList.last loop
        for k in i+1..(allList.last) loop
          if i != k then
            if notStopWord(allList(i), stopList) and notStopWord(allList(k), stopList) then 
              retStr := retStr || andStr || global_nearOper ||'(('||allList(i)||','||allList(k)||'))';
              andStr := '&';
            end if;
          end if;
        end loop;
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i);
        end loop;
      end if;
      retStr := retStr || '</seq>';

      -- STEP 4: ALL words present, anywhere in doc

      andStr := '';
      retStr := retStr || chr(10)||'      <seq>(';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i);
        andStr := '&';
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i);
        end loop;
      end if;
      retStr := retStr || '</seq>';

      -- STEP 5: Some words present

      andStr := '';
      retStr := retStr || chr(10)||'      <seq>';

      if plusList.last > 0 then
        retStr := retStr || '((';
        for i in 1..plusList.last loop
          retStr := retStr || andStr || plusList(i);
          andStr := '&';
        end loop;
        retStr := retStr || ')*10*10)';
      end if;

      andStr := '';
      if plusList.last > 0 then
        retStr := retStr || '&';
      end if;
      retStr := retStr || '(';
      for i in 1..allList.last loop
        retStr := retStr || andStr || allList(i);
        andStr := ',';
      end loop;
      retStr := retStr || ')';

      -- deal with notAllowed words
      if minusList.last > 0 then
        for i in 1..minusList.last loop
          retStr := retStr || '~' || minusList(i);
        end loop;
      end if;
      retStr := retStr || '</seq>';

    end if;

    -- END OF STEPS    

    retStr := retStr || chr(10) || '    </progression>
  </textquery>
  <score datatype="' ||global_scoreType||'"/>
</query>';

  else
    return null;
  end if;

  return retStr;  

  exception
      when value_error then
         raise_application_error(-20701, 'too many words in query - translated query exceeds 4000 chars');
end OTProgRelaxClob;


procedure reParseTest(str varchar2, 
  joinChars varchar2 default '',
  leadChars varchar2 default '',
  endChars  varchar2 default ''
) is
  wordList wordListType;
  i integer;
begin
  --p('reParseTest: str is ' || str);
  reParse(str, wordList, joinChars, leadChars, endChars);
  if wordList is not null and wordList.last > 0 then
    for i in 1..wordList.last() loop
      p(i||': "'||wordList(i)||'"');
    end loop;
  end if;
end;

-- parse a string into words consisting of alphunumerics, optional join characters
-- and optional single leading and trailing wildchars. Double quotes surrounding 
-- multiple word will treat them as a single one

procedure reParse 
  (userStr   in  varchar2, 
   words     out wordListType, 
   joinChars in  varchar2 default '',
   leadChars in  varchar2 default '',
   userWild  in  varchar2 default '*',
   sysWild   in  varchar2 default '%') 
is
  str       varchar2(32767) := userStr;
  pattern   varchar2(2000);
  match     varchar2(2000);
  i         integer;
  lc        varchar2(128);
  ec        varchar2(128);
  joinC     varchar2(128) := joinChars; -- local copy for editing
  jc1       varchar2(128) := '';        -- special position join chars
  jc2       varchar2(128) := '';
  jc3       varchar2(128) := '';
begin

  --p('reParse: str is ' || str);

  if length(leadChars) > 0  then
    lc := '['||leadChars||']?';
  else
    lc := '';
  end if;

  if length(userWild) > 0 then
    ec := '['||userWild||']?';
  else
    ec := '';
  end if;

  -- Posix regular expressions do not allow escaping of characters in 
  -- bracketed strings. If a join character is "]", it MUST appear as
  -- the first character. "^" can appear anywhere BUT first, "-" MUST
  -- appear at the end. That's what I call programmer unfriendly.

  if instr (joinC, ']') > 0 then
    jc1 := ']';
    joinC := replace (joinC, ']', '');
  end if;

  if instr (joinC, '[') > 0 then
    jc1 := jc1 || '[';
    joinC := replace (joinC, '[', '');
  end if;

  if instr (joinC, '^') > 0 then
    jc2 := '^';
    joinC := replace (joinC, '^', '');
  end if;

  if instr (joinC, '-') > 0 then
    jc3 := '-';
    joinC := replace (joinC, '-', '');
  end if;

  pattern := '(' || lc || '[' || jc1 || '[:alnum:]' || joinC || jc2 || jc3 || ']+' || ec ||
              ')|(' || lc || '".+")';
  -- regexp pattern to find an unquoted word
  -- original - didn't work - perhaps if no join chars
  -- pattern := '(' || lc || '[' || jc1 || '[[:alnum:]]' || joinC || jc2 || jc3 || ']+' || ec ||
  --            ')|(' || lc || '".+")';
  -- from backup2
  -- pattern := '(' || lc || '[[:alnum:]' || joinchars || ']+' || ec ||
  --           ')|(' || lc || '".+")';


  -- p(pattern);

  words := wordListType();
  while true loop
    regexp_next_match (str, match, pattern);

    -- deal specially with quoted strings: we need to remove the quotes
    -- and any non-alpha/numeric/join chars, except for + at beginning

    if regexp_instr (match, '^' || lc || '"') > 0 then
       -- remove the quotes, leaving any leading plus
       match := regexp_replace (match, '^('|| lc || ')"(.+)"$', '\1\2');

       -- remove any unwanted chars except + at the start
       if instr (leadChars, substr (match, 1, 1)) > 0 then  
         match := regexp_replace (match, '[^'||jc1||'[:space:][:alnum:]'||joinC||jc2||jc3||']+', ' ', 2);
       else
         match := regexp_replace (match, '[^[:space:][:alnum:]'||joinC||jc2||jc3||']+', ' ');
       end if;
 
       -- squash down multiple spaces
       match := regexp_replace (match, '[[:space:]]+', ' ');
    end if;

    if match is null or length(match) = 0 then
      exit;
    end if;

    -- translate wild card and escape joinchars
    -- OR surround word with braces (braces don't work with wild cards,
    -- backslashes don't escape keywords)

    if substr(match, length(match), 1) = userWild then
       match := substr(match, 1, length(match)-1);
       if length(joinChars) > 0 then
         match := regexp_replace (match, '(['||jc1||joinC||jc2||jc3||'])', '\\\1'); 
       end if;
       match := match || sysWild;
    else
       match := regexp_replace (match, '^('||lc||')(.*)', '\1{\2}');
    end if;

    -- p('adding new word '||match);
    words.extend(1);

    words(words.last()) := match;
    -- p('Word: <'||match||'>');
    exit when str is null or length(str) = 0;
  end loop;

end;
end rep;
/
show errors
--list