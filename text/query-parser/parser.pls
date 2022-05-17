-- Query Parser for Oracle Text
--
-- Quickstart:  Run this file in SQL*Plus  sqlplus user/pw @parser.pls
-- then use functions from this package to translate "end user" queries to Oracle Text
-- syntax
--   SELECT * FROM mytable 
--     WHERE CONTAINS (colname, parser.simpleSearch('+oracle "release date"')) > 0;
--   SELECT * FROM mytable 
--     WHERE CONTAINS (colname, parser.progRelax('+oracle "release date"')) > 0;

-- This package is designed to process an "end-user" query into Oracle Text syntax
-- it should be largely unbreakable, unless the user types something really silly
-- like 5000 'x' characters without a space, we should be able to generate a working
-- query. The only exception is if the section searching syntax is used, and the section
-- specified does not exist.

-- Query syntax modelled loosely on Google/Alta Vista:
--   word : score will be improved if word exists
--   +word : word must exist
--   -word : word CANNOT exist
--   "phrase words" : words treated as phrase (may be preceded by + or -)
--   a word consists of a sequence of alphanumerics and join characters
--   trailing wild cards ONLY are supported: eg oracl* - default char is *
--   no wild cards in phrases
--   Section searching:
--     [+-]section_name:( <search> )
--     where <search> represents any combination of the factors above.
--     There must be no spaces between the colon and open paren. Any matched 
--     parentheses inside will be part of the section search, 
--     Note sections cannot be nested. a:(b c:(d)) will be treated as a:(b c d)
--     or in translated form (b, c, d) WITHIN a
--     Section names are NOT CHECKED. This may produce errors. This is perhaps a
--     "to do" feature for a future version.

-- All other punctuation will be removed, breaking words when appropriate
-- eg. "don't" will be changed to "don t" which is consistent with normal
-- query semantics.

-- Join characters are quoted as necessary. All non-wildcarded words are
-- quoted with braces to avoid keyword problems (eg NT).

-- Query Generators
--   Each of the following functions takes a user-entered query string as an argumen
--   (varchar2) and returns a CLOB value for the translated query string. It is expected
--   that simpleSearch and progRelax will be the most-used functions
--     simpleSearch :  generate a simple search string 
--     phraseSearch :  generate a phrase search matching all words in order
--     nearSearch   :  all words must be NEAR each other
--     andSearch    :  all words must exist in any order
--     proximSearch :  some of the words are near each other
--     accumSearch  :  any of the words exist
--     progRelax    :  combine all of the above options

--  In all cases the MUST / CANNOT exist semantics will be enforced for individual
--  terms and sections.

--  When searching for phrases, all the non-section words will be searched for in order
--  (even if there are sections between the words) 
--  and words within the section will be searched for as phrases as well. For example
--   a b:(c d) e
--  will be converted to something like:
--   (a e) & ( (c d ) WITHIN b )

-- Additional there are several functions which may be called to set various options:

--   setIndexName     (indexName   varchar2 )
--     Specifies the index name for which we want to generate a query. This allows
--     the system to find the JOINCHAR for the index, for more accurate query generation
--     and the stopwords for the index which makes for a more efficient proximSearch
--   SetWildcard      (wildcard    varchar2 )
--     The default wildcard is "*".  You can change it to "%" by calling this function
--     with an argument of '%'
--   SetScoreType     (scoreType   integer  )
--     The default scoretype for progRelax queries is FLOAT. Since the queries generated 
--     are complex, fine grained differences are frequently if integer scoring is used. 
--     Setting  scoreType to scoreTypeInteger (0) will revert to integer scoring.
--   UseNEAR2         (near2Option integer  )
--     Calling this with optionTrue (1) will use the NEAR2 operator rather than NEAR.
--     NEAR2 is a hidden feature in 11.2, and production in the next major release
--   SetMinusOnlyFail (failOption  integer  )
--     If the query resolves to only a single negative term (eg. -cat) this cannot
--     generate a valid Oracle Text query. Normally an empty string will be returned,
--     but if you call SetMinusOnlyFail with optionTrue (1) then it will instead
--     generate an ORA-20704 exception. 

-- Exceptions raised through program/script errors:
-- ORA-20700: index does not exist - you specified an invalid index name
-- ORA-20701: Invalid score type: use 0 for integer, 1 for float
-- ORA-20702: Invalid NEAR2 option: use 0 for NEAR, 1 for NEAR2
-- ORA-20703: Invalid wildcard, must be '%' or '*'
-- ORA-20704: Cannot have a NOT term on its own: you must have other terms
-- ORA-20705: Invalid score type: use 0 for integer, 1 for float
-- ORA-20706: Invalid option for failing on minus only: use 0 for no, 1 for yes

-- Note ORA-20704 is the only error which can be returned by a query function,
-- if a "unary minus" is used, eg [ -cat ] rather than [ dog -cat ]
-- and will only be returned if "setMinusOnlyFail" is call with OptionTrue.

-- NOTE: As supplied, the index specified must be owned by the user calling the
-- code. If you're querying an index owned by another user, you will be able to 
-- specify "schema.indexname" as the argument by doing the following:
--   1/ Uncomment the three sections of code preceded by the comment "uncomment next..."
--   2/ Run the following as either CTXSYS or a DBA user:
--   GRANT SELECT ON ctxsys.ctx_indexes TO <username>
--   GRANT SELECT ON ctxsys.ctx_index_values TO <username>
-- where <username> is the user who will compile and call the package

-- LIMITATIONS: This is designed for space-separated languages and is unlikely to
-- produce good results with Chinese, Japanese, Korean, etc.

-- MAY NOT WORK FULLY with:
--    AUTO_LEXER
--    MULTI_LEXER

-- Version history:
--   Version 0.991:2017-11-07  Fixed regexp bug with repeated quoted phrases
--   Version 0.99: 2015-02-24  Remove hyphens when not preceded by space, prevents
--                             "coca-cola" being treated as "coca NOT cola"
--   Version 0.98: 2013-11-12  Fixed bug where null param prevented default value
--                             so leadng + or - was ignored
--   Version 0.97: 2013-07-26  Added "allWordsRequired" option
--   Version 0.961:2013-02-06  Fixed comment below :(
--   Version 0.96: 2013-16-01  Fixed "setWildCard" - wasn't passing global_wildCard 
--                             to reParse function
--   Version 0.95: 2012-07-11  Published on searchtech blog for comments
--                             Changed file type to .pls and removed SQL*Plus
--                             specific commands for better SQL Developer use
--   Version 0.9:  2012-06-28  Internal Review version
-- This code may be freely copied and/or modified for use with Oracle Text

-- This code is NOT SUPPORTED BY ORACLE : if you use it in your application you
-- must own it and fix any bugs yourself.  The author welcomes feedback and bug
-- reports but makes no commitment to respond in a timely manner.

-- Please send feedback and comments to roger.ford@oracle.com

set serverout on size 1000000
set define off

create or replace package parser is

scoreTypeInteger integer := 0;
scoreTypeFloat   integer := 1;

optionFalse      integer := 0;
optionTrue       integer := 1;

function  simpleSearch     ( inStr      varchar2 ) return clob;
function  phraseSearch     ( inStr      varchar2 ) return clob;
function  nearSearch       ( inStr      varchar2 ) return clob;
function  proximSearch     ( inStr      varchar2 ) return clob;
function  andSearch        ( inStr      varchar2 ) return clob;
function  accumSearch      ( inStr      varchar2 ) return clob;
function  progRelax        ( inStr      varchar2 ) return clob;

procedure setIndexName     (indexName   varchar2 );
procedure SetWildcard      (wildcard    varchar2 );
procedure SetScoreType     (scoreType   integer  );
procedure UseNEAR2         (near2Option integer  );
procedure SetMinusOnlyFail (failOption  integer  );
procedure SetAllWordsReq   (allOption    integer  );

end parser;
/
--list
show errors

create or replace package body parser is

-- datatype used internally in this package

type exprList is table of varchar2(32767);

type queryTerms is record (
  allTerms    exprList ,   -- all the non-section terms, in the order specified
  reqTerms    exprList ,   -- these MUST be present, may include sections
  optTerms    exprList ,   -- these CAN be present, may include sections
  negTerms    exprList     -- these MUST NOT be present
);

type wordListType is table of varchar2(64);

-- Global variables

global_scoreType   varchar2(20) default 'FLOAT';
global_nearOper    varchar2(5)  default 'NEAR';
global_wildCard    varchar2(1)  default '*';
global_failMinus   boolean      default FALSE;
global_allWordsReq boolean      default FALSE;

global_stopList  wordListType;
global_joinChars varchar2(64) default '';

-- for debugging purposes. Can modify this to write to a log file or whatever

procedure p( text varchar2 )
 is
begin
  dbms_output.put_line( text );
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

-- Handle a unary minus : eg "-oracle" with no other terms

procedure handleUnaryMinus is
begin
  if global_failMinus then
    raise_application_error(-20704, 'Cannot have a NOT term on its own: you must have other terms'); 
  end if;
end handleUnaryMinus;

-- Check whether word is in stopword list

function notStopWord (testWord varchar2) return boolean is
  i integer;
  w varchar2(256);
begin
  -- strip any braces
  w := testWord;
  w := replace(w, '{', '');
  w := replace(w, '}', '');

  if global_stopList is null or global_stopList.count() = 0 then
    return true;
  end if;
  for i in 1 .. global_stopList.last loop
    if lower(w) = lower(global_stopList(i)) then
      return false;
    end if;
  end loop;
  return true;
end;

-- parse a string into words consisting of alphunumerics, optional join characters
-- and optional single leading and trailing wildchars. Double quotes surrounding 
-- multiple word will treat them as a single one

procedure reParse (
   userStr   in  clob, 
   words     out wordListType, 
   joinChars in  varchar2 default '',
   leadChars in  varchar2 default '+-',
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
    -- NOTE: this next line is hard-coded to remove hyphen with no spaces to avoid
    -- "coca-cola" being interpreted as "coca NOT cola"
    -- This does not allow for the possibility that "leadChars" might be other than "+" and "-"
    str :=                     regexp_replace(str, '([^[:space:]])-', '\1 ');
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

  -- v0.991 : change second line of regexp to replace . with [^"]
  pattern := '(' || lc || '[' || jc1 || '[:alnum:]' || joinC || jc2 || jc3 || ']+' || ec ||
              ')|(' || lc || '"[^"]+")';
  --p(pattern);

  words := wordListType();
  loop
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

    exit when match is null or length(match) = 0;

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

    --p('adding new word '||match);
    words.extend(1);

    words(words.last()) := match;
    --p('Word: <'||match||'>');
    exit when str is null or length(str) = 0;
  end loop;

end reParse;

-- given a string (subquery), parse it into a queryTerms record
-- qTerms must be initialized before calling this

procedure createQueryTerms (
 queryString in            clob, 
 qTerms      in out nocopy queryTerms,
 clear       in            boolean default false
) is
  words     wordListType;
  firstChar varchar2(1);
  allT   exprList;
  reqT   exprList;
  optT   exprList;
  negT   exprList;
begin

  -- Initialise the table if not already done
  if qterms.allTerms is null or clear then
    allT := exprList();
    reqT := exprList();
    optT := exprList();
    negT := exprList();
    qTerms.allTerms := allT;
    qTerms.reqTerms := reqT;
    qTerms.optTerms := optT;
    qTerms.negTerms := negT;
  end if;

  /* Version 0.91: added last two parameters to this call */
  /* Version 0.98: fixed - null param prevents default value */
  /* reParse (queryString, words, global_joinChars, null, global_wildCard); */
  reParse (queryString, words, global_joinChars, userWild => global_wildCard);

  for i in 1 .. words.count() loop
    firstChar := substr( words(i), 1, 1 );
    if global_allWordsReq then
      case firstChar
        when '+' then
          qTerms.allTerms.extend(1);
          qTerms.allTerms(qTerms.allTerms.last()) := substr( words(i), 2);   
          qTerms.reqTerms.extend(1);
          qTerms.reqTerms(qTerms.reqTerms.last()) := substr( words(i), 2);   
        when '-' then
          qTerms.negTerms.extend(1);
          qTerms.negTerms(qTerms.negTerms.last()) := substr( words(i), 2);   
        else
          qTerms.allTerms.extend(1);
          qTerms.allTerms(qTerms.allTerms.last()) := substr( words(i), 1);   
          qTerms.reqTerms.extend(1);
          qTerms.reqTerms(qTerms.reqTerms.last()) := substr( words(i), 1);   
      end case;
    else  -- all terms are not required
      case firstChar
        when '+' then
          qTerms.allTerms.extend(1);
          qTerms.allTerms(qTerms.allTerms.last()) := substr( words(i), 2);   
          qTerms.reqTerms.extend(1);
          qTerms.reqTerms(qTerms.reqTerms.last()) := substr( words(i), 2);   
        when '-' then
          qTerms.negTerms.extend(1);
          qTerms.negTerms(qTerms.negTerms.last()) := substr( words(i), 2);   
        else
          qTerms.allTerms.extend(1);
          qTerms.allTerms(qTerms.allTerms.last()) := substr( words(i), 1);   
          qTerms.optTerms.extend(1);
          qTerms.optTerms(qTerms.optTerms.last()) := substr( words(i), 1);   
      end case;

    end if;

  end loop;

end createQueryTerms;

-- take a section search such as title:(foo bar) and return a queryTerms object
-- and the section name

procedure parseSection (
  str     in            varchar2, 
  qterms  in out nocopy queryTerms, 
  secName in out nocopy varchar2
) is
  pos     integer;
  re      varchar2(30) := '[[:alnum:]_]:\(';
begin

  pos := regexp_instr(str, re, 1, 1, 1);
  secName := substr( str, 1, pos - 3);
  
  createQueryTerms( substr(str, pos-1), qterms, true);

end parseSection;

-- Construct a simple query string from segments (words, phrases or section searches)
-- Will find all required segments and accumulate over remaining segments

procedure simpleQuery(  
     query    in             queryTerms,
     retStr   in out nocopy  clob 
) is
  reqList      exprList;
  optList      exprList; 
  negList      exprList; 
  conj         varchar2(3)    := '';
  joiner       varchar2(3)    := '';
  secName      varchar2(30);
 
  sectionTerms queryTerms;
  str          clob;
  sectionRE    varchar2(30);
  sectionName  varchar2(30);
begin
  reqList  := query.reqTerms;
  optList  := query.optTerms;
  negList  := query.negTerms;

  retStr := '';

  sectionRE := '[+-]?[[:alnum:]_]+:\(';

    if reqList.count > 0 then

    retStr := retStr || '(';
    for i in 1..reqList.last loop
      if regexp_instr( reqList(i), sectionRE ) = 1 then
        parseSection( reqList(i), sectionTerms, secName );
        simpleQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
          
      else
        retStr := retStr || conj || reqList(i);
      end if;
      conj := '&';
    end loop;
    retStr := retStr || ')';

    joiner := ' & ';
   
  end if;

  if optList.count > 0 then

    conj := '';
    retStr := retStr || joiner || '(';

    if reqList.count > 0 then

      for i in 1..reqList.last loop
        if regexp_instr( reqList(i), sectionRE ) = 1 then
          parseSection( reqList(i), sectionTerms, secName );
          simpleQuery( sectionTerms, str );
          retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
        else
          retStr := retStr || conj || reqList(i);
        end if;
        conj := ',';
      end loop;

    end if;

    for i in 1..optList.last loop
      if regexp_instr( optList(i), sectionRE ) = 1 then
        parseSection( optList(i), sectionTerms, secName );
        simpleQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      else
        retStr := retStr || conj || optList(i);
      end if;
      conj := ',';
    end loop;

    retStr := retStr || ')';

  end if;

  if negList.count > 0 then
    for i in 1..negList.last loop
      if regexp_instr( negList(i), sectionRE ) = 1 then
        parseSection( negList(i), sectionTerms, secName );
        simpleQuery( sectionTerms, str );
        retStr := retStr || ' ~' || '((' || str || ') WITHIN '|| secName || ')';
      else
        retStr := retStr || ' ~' || negList(i);
      end if;
    end loop; 
  end if;

end simpleQuery;

-- Construct a query where all terms are used
-- Expect to find all standard words ANDed together 
-- and all sections where all words in section exist
-- eg if user enters
-- a b c:(d e) f
-- then we return "( a & b & f ) & ( (d & e) WITHIN c )

procedure andQuery(  
     query    in             queryTerms,
     retStr   in out nocopy  clob 
) is
  allList      exprList;
  reqList      exprList;
  optList      exprList; 
  negList      exprList; 
  conj         varchar2(3)    := '';
  joiner       varchar2(3)    := '';
  secName      varchar2(30);
 
  sectionTerms queryTerms;
  str          clob;
  sectionRE    varchar2(30);
  sectionName  varchar2(30);
begin
  allList  := query.allTerms;
  reqList  := query.reqTerms;
  optList  := query.optTerms;
  negList  := query.negTerms;

  retStr := '';

  sectionRE := '[+-]?[[:alnum:]_]+:\(';

  -- All simple terms are added as a phrase search

  conj := '';

  if allList.count > 0 then
    retStr := retStr || '(';
    for i in 1..allList.last loop
      retStr := retStr || conj || allList(i);
      conj := '&';
    end loop;
    retStr := retStr || ')';

    conj := '&';

  end if;

  -- Any sections in required or optional list have to be added
  -- section contents recursively submitted to this function
  if reqList.count > 0 then
    for i in 1..reqList.last loop
      if regexp_instr( reqList(i), sectionRE ) = 1 then
        parseSection( reqList(i), sectionTerms, secName );
        andQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := '&';
    end loop;
  end if;

  if optList.count > 0 then
    for i in 1..optList.last loop
      if regexp_instr( optList(i), sectionRE ) = 1 then
        parseSection( optList(i), sectionTerms, secName );
        andQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := '&';
    end loop;
  end if;

  -- finally any negative terms (sections or single terms) must be added
  -- note that -a:(b +c) should only be subtracted if c is present TODO: is this right?

  if negList.count > 0 then
    if reqList.count = 0 and optList.count = 0 then 
      handleUnaryMinus();
      retStr := '';
    else
      for i in 1..negList.last loop
        if regexp_instr( negList(i), sectionRE ) = 1 then
          parseSection( negList(i), sectionTerms, secName );
          simpleQuery( sectionTerms, str );
          retStr := retStr || ' ~' || '((' || str || ') WITHIN '|| secName || ')';
        else
          retStr := retStr || ' ~' || negList(i);
        end if;
      end loop; 
    end if;
  end if;

end andQuery;

-- Construct a query where all terms are ACCUMed
-- Expect to find all standard words ACCUMed together 
-- ACCUMed with all sections where the words in the sections
-- are ACCUMed too.  Additionally we must add all required 
-- words and sections
-- eg 1 if user enters
-- a b c:(d e) f
-- then we return "(a, b, f) , ((d, e) WITHIN c)"
-- eg 2 if user enters
-- +x +y a b c:(d e) f -z
-- then we return
---(x, y, a, b, f) , ( (d, e) WITHIN c) & x & y ~z

procedure accumQuery(  
     query    in             queryTerms,
     retStr   in out nocopy  clob 
) is
  allList      exprList;
  reqList      exprList;
  optList      exprList; 
  negList      exprList; 
  conj         varchar2(3)    := '';
  joiner       varchar2(3)    := '';
  secName      varchar2(30);
 
  sectionTerms queryTerms;
  str          clob;
  sectionRE    varchar2(30);
  sectionName  varchar2(30);
begin
  allList  := query.allTerms;
  reqList  := query.reqTerms;
  optList  := query.optTerms;
  negList  := query.negTerms;

  retStr := '';

  sectionRE := '[+-]?[[:alnum:]_]+:\(';

  -- All simple terms are added as a accumulated terms

  conj := '';

  retStr := retStr || '((';

  if allList.count > 0 then
    retStr := retStr || '(';
    for i in 1..allList.last loop
      retStr := retStr || conj || allList(i);
      conj := ',';
    end loop;
    retStr := retStr || ')';

    conj := ',';

  end if;


  -- Any sections in required or optional list have to be added
  -- section contents recursively submitted to this function
  if reqList.count > 0 then
    for i in 1..reqList.last loop
      if regexp_instr( reqList(i), sectionRE ) = 1 then
        parseSection( reqList(i), sectionTerms, secName );
        accumQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := ',';
    end loop;
  end if;

  if optList.count > 0 then
    for i in 1..optList.last loop
      if regexp_instr( optList(i), sectionRE ) = 1 then
        parseSection( optList(i), sectionTerms, secName );
        accumQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := ',';
    end loop;
  end if;

  retStr := retStr || ')';

  -- now add any required terms

  if reqList.count > 0 then
    conj := '&';
    for i in 1..reqList.last loop
      if regexp_instr( reqList(i), sectionRE ) = 1 then
        parseSection( reqList(i), sectionTerms, secName );
        simpleQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      else
        retStr := retStr || conj || reqList(i);
      end if;
    end loop;
   
  end if;

  -- finally any negative terms (sections or single terms) must be added
  -- note that -a:(b +c) should only be subtracted if c is present TODO: is this right?

  if negList.count > 0 then
    if reqList.count = 0 and optList.count = 0 then 
      handleUnaryMinus();
      retStr := '';
    else
      for i in 1..negList.last loop
        if regexp_instr( negList(i), sectionRE ) = 1 then
          parseSection( negList(i), sectionTerms, secName );
          simpleQuery( sectionTerms, str );
          retStr := retStr || ' ~' || '((' || str || ') WITHIN '|| secName || ')';
        else
          retStr := retStr || ' ~' || negList(i);
        end if;
      end loop; 
    end if;
  end if;

  -- need to close parantheses UNLESS query zerod due to minus only query
  if length(retStr) > 0 then 
    retStr := retStr || ')';
  end if;

end accumQuery;

-- create a NEAR query
-- eg "a b c +d e(f g) -h"
-- => NEAR((a,b,c,d)) & (NEAR((f,g)) WITHIN e) 

procedure nearQuery(  
     query    in             queryTerms,
     retStr   in out nocopy  clob 
) is
  allList      exprList;
  reqList      exprList;
  optList      exprList; 
  negList      exprList; 
  conj         varchar2(3)    := '';
  joiner       varchar2(3)    := '';
  secName      varchar2(30);
 
  sectionTerms queryTerms;
  str          clob;
  sectionRE    varchar2(30);
  sectionName  varchar2(30);
begin
  allList  := query.allTerms;
  reqList  := query.reqTerms;
  optList  := query.optTerms;
  negList  := query.negTerms;

  retStr := '';

  sectionRE := '[+-]?[[:alnum:]_]+:\(';

  -- All simple terms are added as a near search

  conj := '';

  if allList.count > 0 then
    retStr := retStr || global_nearOper||'((';
    for i in 1..allList.last loop
      retStr := retStr || conj || allList(i);
      conj := ',';
    end loop;
    retStr := retStr || '))';

    conj := '&';

  end if;

  -- Any sections in required or optional list have to be added
  -- section contents recursively submitted to this function
  if reqList.count > 0 then
    for i in 1..reqList.last loop
      if regexp_instr( reqList(i), sectionRE ) = 1 then
        parseSection( reqList(i), sectionTerms, secName );
        nearQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := '&';
    end loop;
  end if;

  if optList.count > 0 then
    for i in 1..optList.last loop
      if regexp_instr( optList(i), sectionRE ) = 1 then
        parseSection( optList(i), sectionTerms, secName );
        nearQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := '&';
    end loop;
  end if;

  -- finally any negative terms (sections or single terms) must be added
  -- note that -a:(b +c) should only be subtracted if c is present TODO: is this right?

  if negList.count > 0 then
    if reqList.count = 0 and optList.count = 0 then 
      handleUnaryMinus();
      retStr := '';
    else
      for i in 1..negList.last loop
        if regexp_instr( negList(i), sectionRE ) = 1 then
          parseSection( negList(i), sectionTerms, secName );
          simpleQuery( sectionTerms, str );
          retStr := retStr || ' ~' || '((' || str || ') WITHIN '|| secName || ')';
        else
          retStr := retStr || ' ~' || negList(i);
        end if;
      end loop; 
    end if;
  end if;

end nearQuery;

-- proxim: all word must be present, some near to each other
-- eg "a b c +d e(f g) -h"
-- => NEAR((a,b,c,d)) & (NEAR((f,g)) WITHIN e) ~h

procedure proximQuery(  
     query    in             queryTerms,
     retStr   in out nocopy  clob 
) is
  allList      exprList;
  reqList      exprList;
  optList      exprList; 
  negList      exprList; 
  conj         varchar2(3)    := '';
  joiner       varchar2(3)    := '';
  secName      varchar2(30);
 
  sectionTerms queryTerms;
  str          clob;
  sectionRE    varchar2(30);
  sectionName  varchar2(30);
begin
  allList  := query.allTerms;
  reqList  := query.reqTerms;
  optList  := query.optTerms;
  negList  := query.negTerms;

  retStr := '';

  sectionRE := '[+-]?[[:alnum:]_]+:\(';

  -- All simple terms are added as a set of NEAR pairs, accumulated together

  conj := '';

  if allList.count > 0 then

    if allList.count < 2 then
      -- if only one term just specify it, don't try to use NEAR
      retStr := retStr || allList(1);
    else
      retStr := retStr || '(';
      for i in 1..allList.last loop
        for k in i+1..(allList.last) loop
          if i != k then
            if notStopWord(allList(i)) and notStopWord(allList(k)) then 
              retStr := retStr || conj ||global_nearOper||'(('||allList(i)||','||allList(k)||'))';
              conj := ',';
            end if;
          end if;
        end loop;
      end loop;
      retStr := retStr || ')';
    end if;
    conj := '&';

  end if;

  -- Any sections in required or optional list have to be added
  -- section contents recursively submitted to this function
  if reqList.count > 0 then
    for i in 1..reqList.last loop
      if regexp_instr( reqList(i), sectionRE ) = 1 then
        parseSection( reqList(i), sectionTerms, secName );
        proximQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := '&';
    end loop;
  end if;

  if optList.count > 0 then
    for i in 1..optList.last loop
      if regexp_instr( optList(i), sectionRE ) = 1 then
        parseSection( optList(i), sectionTerms, secName );
        proximQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := '&';
    end loop;
  end if;

  -- now add any required terms

  if reqList.count > 0 then
    conj := '&';
    for i in 1..reqList.last loop
      if regexp_instr( reqList(i), sectionRE ) = 1 then
        parseSection( reqList(i), sectionTerms, secName );
        simpleQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      else
        retStr := retStr || conj || reqList(i);
      end if;
    end loop;
   
  end if;

  -- finally any negative terms (sections or single terms) must be added
  -- note that -a:(b +c) should only be subtracted if c is present TODO: is this right?

  if negList.count > 0 then
    if reqList.count = 0 and optList.count = 0 then 
      handleUnaryMinus();
      retStr := '';
    else
      for i in 1..negList.last loop
        if regexp_instr( negList(i), sectionRE ) = 1 then
          parseSection( negList(i), sectionTerms, secName );
          simpleQuery( sectionTerms, str );
          retStr := retStr || ' ~' || '((' || str || ') WITHIN '|| secName || ')';
        else
          retStr := retStr || ' ~' || negList(i);
        end if;
      end loop; 
    end if;
  end if;

end proximQuery;

-- Construct a phrase query from segments (words, phrases or section searches)
-- Expect to find all standard words as a single phrase, and this phrase is 
-- ANDed with phrases within sections. eg if user enters
-- a b c:(d e) f
-- then we return "( a b f ) & ( (d e) WITHIN c )

procedure phraseQuery(  
     query    in             queryTerms,
     retStr   in out nocopy  clob 
) is
  allList      exprList;
  reqList      exprList;
  optList      exprList; 
  negList      exprList; 
  conj         varchar2(3)    := '';
  joiner       varchar2(3)    := '';
  secName      varchar2(30);
 
  sectionTerms queryTerms;
  str          clob;
  sectionRE    varchar2(30);
  sectionName  varchar2(30);
begin
  allList  := query.allTerms;
  reqList  := query.reqTerms;
  optList  := query.optTerms;
  negList  := query.negTerms;

  retStr := '';

  sectionRE := '[+-]?[[:alnum:]_]+:\(';

  -- All simple terms are added as a phrase search

  conj := '';

  if allList.count > 0 then
    retStr := retStr || '(';
    for i in 1..allList.last loop
      retStr := retStr || conj || allList(i);
      conj := ' ';
    end loop;
    retStr := retStr || ')';

    conj := '&';

  end if;

  -- Any sections in required or optional list have to be added
  -- section contents recursively submitted to this function
  if reqList.count > 0 then
    for i in 1..reqList.last loop
      if regexp_instr( reqList(i), sectionRE ) = 1 then
        parseSection( reqList(i), sectionTerms, secName );
        phraseQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := '&';
    end loop;
  end if;

  if optList.count > 0 then
    for i in 1..optList.last loop
      if regexp_instr( optList(i), sectionRE ) = 1 then
        parseSection( optList(i), sectionTerms, secName );
        phraseQuery( sectionTerms, str );
        retStr := retStr || conj || '((' || str || ') WITHIN '|| secName || ')';
      end if;
      conj := '&';
    end loop;
  end if;

  -- finally any negative terms (sections or single terms) must be added
  -- note that -a:(b +c) should only be subtracted if c is present TODO: is this right?

  if negList.count > 0 then
    if reqList.count = 0 and optList.count = 0 then 
      handleUnaryMinus();
      retStr := '';
    else
      for i in 1..negList.last loop
        if regexp_instr( negList(i), sectionRE ) = 1 then
          parseSection( negList(i), sectionTerms, secName );
          simpleQuery( sectionTerms, str );
          retStr := retStr || ' ~' || '((' || str || ') WITHIN '|| secName || ')';
        else
          retStr := retStr || ' ~' || negList(i);
        end if;
      end loop; 
    end if;
  end if;

end phraseQuery;

-- progQuery - generate a progressive relaxation query
-- generates steps from other xxQuery procedures
-- STEP 1 : phrase
-- STEP 2 : near (all words)
-- STEP 3 : and
-- STEP 4 : some near (proxim)
-- STEP 5 : accum

procedure progQuery (
     query    in             queryTerms,
     retStr   in out nocopy  clob 
) is
  allList  exprList;
  reqList  exprList;
  optList  exprList; 
  negList  exprList; 
  andStr   varchar2(5)     := '';
  joiner   varchar2(5)     := '';
  str      varchar2(32767) := '';
  str2     varchar2(32767) := '';
  re       varchar2(30);
begin
  allList := query.allTerms;
  reqList := query.reqTerms;
  optList := query.optTerms;
  negList := query.negTerms;

  -- return an empty query if nothing specified
  -- fail if required if only a negative term specified

  if reqList.count = 0 and optList.count = 0 then
    if negList.count > 0 then
      handleUnaryMinus();
    end if;
    retStr := '';
    return;
  end if;

  retStr  := '
<query>
  <textquery>
    <progression>';

  -- STEP 1 : phrase
  --          do a phrase search but boost with simple query
  --          then scores higher for multiple terms

  phraseQuery( query, str );
  simpleQuery( query, str2 );

  retStr := retStr || chr(10) || '      <seq>';
  retStr := retStr || 'DEFINEMERGE( ( (' || str || '),('|| str2 || ') ), AND, ADD )';
  retStr := retStr || '</seq>';

  -- STEP 2 : near

  nearQuery   ( query, str );
  simpleQuery ( query, str2 );

  retStr := retStr || chr(10) || '      <seq>';
  retStr := retStr || 'DEFINEMERGE( ( (' || str || '),('|| str2 || ') ), AND, ADD )';
  retStr := retStr || '</seq>';

  -- STEP 3 : and

  andQuery    ( query, str );
  simpleQuery ( query, str2 );

  retStr := retStr || chr(10) || '      <seq>';
  retStr := retStr || 'DEFINEMERGE( ( (' || str || '),('|| str2 || ') ), AND, ADD )';
  retStr := retStr || '</seq>';

  -- STEP 4 : some near (proxim)

  proximQuery( query, str );
  simpleQuery ( query, str2 );

  retStr := retStr || chr(10) || '      <seq>';
  retStr := retStr || 'DEFINEMERGE( ( (' || str || '),('|| str2 || ') ), AND, ADD )';
  retStr := retStr || '</seq>';

  -- STEP 5 : accum

  accumQuery( query, str );
  retStr := retStr || chr(10) || '      <seq>' || str || '</seq>';

  retStr := retStr || '
    </progression>
  </textquery>
  <score datatype="'||global_scoreType||'"/>
</query>';

end progQuery;

procedure strToQuery (
  queryStr      in varchar2, 
  simpleQry     in out nocopy clob
) is
  qTerms queryTerms;

begin

  createQueryTerms (queryStr, qTerms, true);
  simpleQuery( qTerms, simpleQry);

end strToQuery;

-- find the first regexp in a string, return string with that 
-- regexp removed, and the match itself. Also return any 
-- preceding string

procedure regexp_split 
  (str in out varchar2, match out varchar2, pattern varchar2, preceed in out varchar2) 
is
  rest     varchar2(32767) := str;
  newstart integer;
  reStart  integer;
begin
     match := regexp_substr(rest, pattern, 1, 1, 'n');
     -- find start of re
     reStart := regexp_instr(rest, pattern, 1, 1, 0, 'n');
     -- find end of re
     newStart := regexp_instr(rest, pattern, 1, 1, 1, 'n');
     preceed := substr(str, 1, reStart-1);
     str := substr(rest, newstart, length(rest)-newstart+1);
end;

-- Find end of a parenthesised string
-- start points at first open paren, we track until we reach a corresponding close
-- paren.  Can't do this in regular expressions
-- returns character position of closing paren

function  getSectionEnd( qStr in out nocopy clob, startPos integer ) return integer is
  pos number;
  openCount number := 0;
  closeCount number := 0;
begin
  pos := startPos;
  loop 
   exit when pos > length(qStr);
    if substr(qStr, pos, 1) = '(' then
      openCount := openCount + 1;
    elsif substr(qStr, pos, 1) = ')' then
      closeCount := closeCount + 1;
    end if;
   exit when closeCount = openCount;
    pos := pos + 1;
  end loop;

  return pos;

end getSectionEnd;

-- find all the section searches in a query
-- a set of querySegments is returned, which is a list of simple terms 
-- (translated into Oracle Text syntax) and section searches in their 
-- original untranslated format

procedure sectionSplitter ( 
  queryText      in             clob,         -- query to process
  querySegments  in out nocopy queryTerms    -- list of expressions
) is

   allTerms  exprList;
   reqTerms  exprList;
   optTerms  exprList;
   negTerms  exprList;
   
   re        varchar2(255);
   qry       clob;
   firstChar varchar2(1);

   counter integer;       -- prevent loops while testing
   loopmax integer := 9999;  --  -- "" --

   rstart    integer;     -- start of regexp marking title
   rend      integer;     -- end of regexp marking title
   secEnd    integer;     -- length of section in parens

   secQry    varchar2(32767); -- parsed section query
begin

  if querySegments.allTerms is null then 
    -- Initialise the table
    allTerms := exprList();
    reqTerms := exprList();
    optTerms := exprList();
    negTerms := exprList();
    querySegments.allTerms := allTerms;
    querySegments.reqTerms := reqTerms;
    querySegments.optTerms := optTerms;
    querySegments.negTerms := negTerms;
  end if;

  counter := 0;
 
  qry := queryText;     -- get local copy so we can change it

  -- regexp to match the start of a section search eg +sect_name:(dog cat)
  re := '[+-]?[[:alnum:]_]+:\(';
  -- loop round extracting section searches from query text
  loop

    counter := counter + 1;
    exit when counter > loopmax;

    rstart := regexp_instr(qry, re, 1, 1, 0, 'n');
   exit when rstart = 0;
    rend   := regexp_instr(qry, re, 1, 1, 1, 'n'); 

    -- find the end of the section
    secEnd   := getSectionEnd( qry, rend-1); 
 
    firstChar := substr(qry, rstart, 1);

    case firstChar
      when '+' then 
        querySegments.reqTerms.extend(1);
        querySegments.reqTerms(querySegments.reqTerms.last()) := 
          substr(qry, rstart + 1, secEnd - rstart);
      when '-' then
        querySegments.negTerms.extend(1);
        querySegments.negTerms(querySegments.negTerms.last()) := 
          substr(qry, rstart + 1, secEnd - rstart);
      else
        querySegments.optTerms.extend(1);
        querySegments.optTerms(querySegments.optTerms.last()) := 
          substr(qry, rstart, secEnd - rstart + 1);
    end case;

    -- qry now becomes the query with this section search removed
    qry := substr(qry, 1, rstart-1) || substr(qry, secEnd + 1);

  end loop;

  -- Remainder in qry is the query with all section subqueries removed.
  -- process it to extract all the simple query terms and add these
  -- to querySegments before returning it
  -- set clear = false to add rather than replace contents

  createQueryTerms( qry, querySegments, false );
  
end sectionSplitter;

-- Split schema and indexname eg scott.myindex -> scott, myindex

procedure getSchemaAndIndex(
  fullIndexName in     varchar2, 
  schemaName    in out varchar2, 
  indexName     in out varchar2
) is
   p integer;
begin
   
   p := instr(fullIndexname, '.');
   if p = 0 then
      schemaName := null;
      indexName  := fullIndexName;
   else
      schemaName := substr(fullIndexName, 1, p-1);
      indexName  := substr(fullIndexName, p+1);
   end if; 
   
end;

-- Check that the index name (and possibly schema) are valid

procedure validateIndexName(schemaName in varchar2, indexName in varchar2) is
  ixName varchar2(64);
begin
  if schemaName is null then
    begin
      select indexName into ixName from ctx_user_indexes
      where upper(indexName) = idx_name;
    exception 
      when no_data_found then
        raise_application_error (-20700, 'Index does not exist: '|| indexName);
    end;
  -- uncomment next 9 lines if you want to be able to specify "schema.indexname"
  -- user will have to be granted select access on ctxsys.ctx_indexes
  --else 
  --  begin
  --    select indexName into ixName from ctxsys.ctx_indexes
  --    where upper(indexName) = idx_name
  --    and upper(schemaName) = idx_owner;
  --  exception 
  --    when no_data_found then
  --      raise_application_error (-20700, 'Index does not exist: '|| schemaName || '.' || indexName);
  --  end;
  -- end of section to uncomment    
  end if;
end;

procedure getStopWords(schemaName in varchar2, indexName in varchar2) is
  type stopword is table of varchar2(64);
begin
  -- Initialize stopList
  global_stopList := wordListType();
  -- leave empty stopList table if no index specified
  if indexName is null or indexName = '' then
    return;
  end if;
  if schemaName is null then
    for c in (select ixv_value from ctx_user_index_values
         where ixv_index_name = upper(indexName)
         and ixv_class        = 'STOPLIST'
         and ixv_attribute    = 'STOP_WORD') loop
      global_stopList.extend(1);
      global_stopList(global_stopList.last) := c.ixv_value;
    end loop;
  -- uncomment next 9 lines if you wish to be able to specify "schema.indexname"
  -- user will have to be granted select access on ctxsys.ctx_index_values
  --else -- schema name is specified
  --  for c in (select ixv_value from ctxsys.ctx_index_values
  --       where ixv_index_name = upper(indexName)
  --       and ixv_index_owner  = upper(schemaName)
  --       and ixv_class        = 'STOPLIST'
  --       and ixv_attribute    = 'STOP_WORD') loop
  --    global_stopList.extend(1);
  --    global_stopList(global_stopList.last) := c.ixv_value;
  --  end loop;
  -- end of section to uncomment
  end if;
end;


procedure getJoinChars(schemaName in varchar2, indexName in varchar2) is
begin
  global_joinChars := '';
  -- empty indexName => Clear the set of join characters
  if indexName is null or indexName = '' then
    return;
  end if;
  if schemaName is null then
    for c in (select ixv_value from ctx_user_index_values
         where ixv_index_name = upper(indexName)
         and ixv_class        = 'LEXER'
         and ( ixv_attribute  = 'PRINTJOINS'
            or ixv_attribute  = 'SKIPJOINS' ) ) loop
      global_joinchars := global_joinchars || c.ixv_value;
    end loop;
  -- uncomment next 9 lines if you wish to be able to specify "schema.indexname"
  -- user will have to be granted select access on ctxsys.ctx_index_values
  --else
  --  for c in (select ixv_value from ctxsys.ctx_index_values
  --       where ixv_index_name = upper(indexName)
  --       and ixv_index_owner  = upper(schemaName)
  --       and ixv_class        = 'LEXER'
  --       and ( ixv_attribute  = 'PRINTJOINS'
  --          or ixv_attribute  = 'SKIPJOINS' ) ) loop
  --    global_joinchars := global_joinchars || c.ixv_value;
  --  end loop;
  -- end of section to uncomment
  end if;
end;

function simpleSearch( inStr varchar2 ) return clob is
  query  queryTerms;
  final  clob;
begin

  sectionSplitter ( inStr, query );
  simpleQuery     ( query, final );
  return final;

end simpleSearch;

function phraseSearch( inStr varchar2 ) return clob is
  query  queryTerms;
  final  clob;
begin

  sectionSplitter ( inStr, query );
  phraseQuery     ( query, final );
  return final;

end phraseSearch;

function andSearch( inStr varchar2 ) return clob is
  query  queryTerms;
  final  clob;
begin

  sectionSplitter ( inStr, query );
  andQuery        ( query, final );
  return final;

end andSearch;

function nearSearch( inStr varchar2 ) return clob is
  query  queryTerms;
  final  clob;
begin

  sectionSplitter ( inStr, query );
  nearQuery       ( query, final );
  return final;

end nearSearch;

function proximSearch( inStr varchar2 ) return clob is
  query  queryTerms;
  final  clob;
begin

  sectionSplitter ( inStr, query );
  proximQuery     ( query, final );
  return final;

end proximSearch;

function accumSearch( inStr varchar2 ) return clob is
  query  queryTerms;
  final  clob;
begin

  sectionSplitter ( inStr, query );
  accumQuery      ( query, final );
  return final;

end accumSearch;

function progRelax( inStr varchar2 ) return clob is
  query  queryTerms;
  final  clob;
begin

  sectionSplitter ( inStr, query );
  progQuery       ( query, final );
  return final;

end progrelax;

procedure setAllWordsReq (allOption integer)
 is
begin
 if allOption = optionTrue then
   global_allWordsReq := TRUE;
 elsif allOption = optionFalse then
   global_allWordsReq := FALSE;
 else
   raise_application_error (-20707, 'Invalid option for all words required: use 0 for no, 1 for yes');
 end if;
end setAllWordsReq;

procedure setMinusOnlyFail (failOption integer)
 is
begin
  if failOption = optionTrue then
    global_failMinus := TRUE;
  elsif failOption = optionFalse then
    global_failMinus := FALSE;
  else
    raise_application_error (-20706, 'Invalid option for failing on minus only: use 0 for no, 1 for yes');
  end if;
end setMinusOnlyFail;

-- set index name
-- fetches join character list and stopwords into global variables
-- where they will be used by the next query generator

procedure setIndexName (indexName varchar2) is
  schemaName      varchar2(30) := '';
  idxName         varchar2(30) := '';
begin
  getSchemaAndIndex( indexName, schemaName, idxName );
  validateIndexName( schemaName, idxName );
  getJoinChars     ( schemaName, idxName );
  getStopWords     ( schemaName, idxName );
end setIndexName;

procedure SetScoreType (scoreType integer)
 is
begin
  if scoreType = scoreTypeFloat then
    global_scoreType := 'FLOAT';
  elsif scoreType = scoreTypeInteger then
    global_scoreType := 'INTEGER';
  else
    raise_application_error (-20705, 'Invalid score type: use 0 for integer, 1 for float');
  end if;
end;

procedure UseNEAR2     (near2Option integer)
 is
begin
  if near2Option = optionTrue then 
    global_nearOper := 'NEAR2';
  elsif near2Option = optionFalse then
    global_nearOper := 'NEAR';
  else
    raise_application_error (-20702, 'Invalid NEAR2 option: use 0 for NEAR, 1 for NEAR2');
  end if;
end;

procedure SetWildCard (wildcard varchar2)
 is
begin
  if wildcard = '%' then
    global_wildcard := wildcard;
  elsif wildcard = '*' then
    global_wildcard := wildcard;
  else
    raise_application_error (-20703, 'Invalid wildcard: must be ''%'' or ''*''');
  end if;
end;

end parser;
/
-- list
show errors
