-- Concatenated Datastore

-- Procedures to automatically create a user datastore that
-- concatenates multiple columns into a single column index.

-- This file must be run by the CTXSYS user

-- The concatenated datastore allows you to create a single index
-- over multiple columns of a table.  Each column is indexed in
-- its own section.

-- Using the package:
-- Creating a concatenated datastore is something like creating
-- a section group.
-- 
-- First we call 
--     ctx_cd.create_cdstore('my_cdstore', 'tablename');
-- Then we add our required columns:
--     ctx_cd.add_column('my_cdstore', 'title_col', 'titlesection');
--     ctx_cd.add_column('author', 'author_col', 'auth');
-- ("titlesection" and "auth" are the names given to the sections created)
--
-- The calls create a datastore preference and a section
--   group, both with the name "my_cdstore".  I can add extra section 
--   definitions to the section group if required, then create my index:

--     create index my_index on tablename indextype is ctxsys.context
--       parameters ('datastore my_cdstore section group my_cdstore');

-- Version 1.0.0  9 Nov 1999   Roger Ford   raford@uk.oracle.com
--                Initial released version
--         1.0.1  9 Dec 1999   Roger Ford   raford@uk.oracle.com
--                Performance workshop release
--                allow dates with no range (treat as char)
--                other minor changes
--         1.0.2  Move trigger to user schema - otherwise trigger
--                name will conflict if two users have same cdstore name.
--
-- TO DO LIST FOR THIS VERSION
-- check effects on scores
-- string_contains function for consistency
-- visible = false for range column defaults?
-- check two cols with same tag
-- name section group differently - problems with i/face
-- drop trigger in case its on another table
-- problem with LONG and CLOB together?

-- TO DO LIST FOR FUTURE VERSIONS
-- order columns are returned - does this matter?
-- allow for null tags / no section definition for specified columns
-- auto_section_group for 8.1.6

set echo off
--connect ctxsys/ctxsys
-- uncomment these lines to use trace_source for debugging
--drop table trace_source;
--create table trace_source (proc_buffer varchar2(4000));
--truncate table trace_source;

drop table ctx_cdstores;

create table ctx_cdstores (
  cdstore_id   number(10) primary key,
  cdstore_name varchar2(30),
  owner        varchar2(30),
  table_name   varchar2(30)
);

drop table ctx_cdstore_cols;

create table ctx_cdstore_cols (
  cdstore_id   number(10),
  column_name  varchar2(30),
  section_name varchar2(30),
  visible      char(1),
  col_type     varchar2(6),
  min_int      number(8,0),
  max_int      number(8,0),
  min_date     date,
  max_date     date
  );

create or replace view ctx_user_cdstores as
  select cdstore_id, cdstore_name, table_name
    from ctx_cdstores
    where owner = user;

grant select on ctx_user_cdstores
  to ctxapp;

drop public synonym ctx_user_cdstores;
create public synonym ctx_user_cdstores 
  for ctxsys.ctx_user_cdstores;

create or replace view ctx_user_cdstore_cols as
  select a.cdstore_id, a.cdstore_name, 
         b.column_name, b.section_name, b.visible, 
         b.col_type, b.min_int, b.max_int,
         b.min_date, b.max_date
    from ctx_cdstores a, ctx_cdstore_cols b
    where owner = user
    and a.cdstore_id = b.cdstore_id;

grant select on ctx_user_cdstore_cols
  to ctxapp;

drop public synonym ctx_user_cdstore_cols;
create public synonym ctx_user_cdstore_cols 
  for ctxsys.ctx_user_cdstore_cols;

drop sequence ctx_cdstore_seq;
create sequence ctx_cdstore_seq;

-- The "Friedman" algorithm
-- With thanks to Mike Friedman

-- Encode integer and date values in character strings
-- Allows range searching on numerics 
-- within an interMedia Text index

-- Avoid use of multiple indexes on mixed searches which
-- require range searching (greater than, less than, between)

create or replace package Friedman as
/*
  The range of values to be encoded must be specified up front
  Smaller ranges are more efficient in index space and query speed

  The 'base' is selected according to the required range

  Base |    Max |   Year(base 1/1/1990)|  Avg.Storage (bytes)
  ==== | ====== | ==================== | ===========
     2 |     15     16-JAN-1990             16
     3 |     80     22-MAR-1990             36
     4 |    255     13-SEP-1990             64
     5 |    624     17-SEP-1991            100
     6 |   1295     19-JUL-1993            144
     7 |   2400     28-JUL-1996            196
     8 |   4095     19-MAR-2001            256
     9 |   6560     18-DEC-2007            324
    10 |   9999     18-MAY-2017            400
    11 |  14640     21-JAN-2030            484
    12 |  20735     09-OCT-2046            576
    13 |  28560     12-MAR-2068            676
    14 |  38415     06-MAR-2095            784
    15 |  50624     09-AUG-2128            900
    16 |  65535     06-JUN-2169           1024
    17 |  83520     03-SEP-2218           1156
    18 | 104975     31-MAY-2277           1296
    19 | 130320     22-OCT-2346           1444
    20 | 159999     24-JAN-2428           1600

  Note: for base in (2..6) the 2-character pseudo-digit scheme is
        "wasted" since 6**2=36 can be represented in
        0..9, A..Z. (7*2 can be represented in 0..9, A..Z, a..z.)

        Thus a more compact representation is possible for integer
        ranges with cardinality LE 1295 (or 2400 w/ case-sensive indexing).
*/
  procedure Init 
    ( p_min        in integer,
      p_max        in integer 
    );

  function GetRange (min_int integer, max_int integer)
      return integer;

  function EncodeInteger
    ( p_integer    in number /* in range g_min_integer..g_max_integer */
    ) 
      return          varchar2; /* guaranteed to fit in varchar2(4000) */
            
  function IntegerContainsCriteria
    ( p_integer        in number,  /* in range g_min_integer..g_max_integer */
      p_other_integer  in number,  /* in range g_min_integer..g_max_integer */
      p_operator       in varchar2 /* 'E' ==>  = p_integer 
                                      'G' ==> >= p_integer
                                      'L' ==> <= p_integer
                                      'B' ==> >= p_integer and
                                              <= p_other_integer */
    ) 
      return           varchar2; /* guaranteed to fit in varchar2(4000) */

  function EncodeDate
    ( p_date           in date  /* must be within range specified in Init */
    )
      return           varchar2; /* guaranteed to fit in varchar2(2000) */ 

end Friedman;
/
Show errors
--list

create or replace package body Friedman as

  g_base                    integer;
  g_pseudo_digit_base       integer;
  g_min_integer             integer;
  g_max_integer             integer;

  g_min_date                date;
  g_max_date                date;

  g_hi_prefix               constant varchar2(1) :=             'H';
  g_lo_prefix               constant varchar2(1) :=             'L';
  -- if alphanumerics not used for above, then prepend '\' below
  g_hi_escaped_prefix       constant varchar2(2) := g_hi_prefix;
  g_lo_escaped_prefix       constant varchar2(2) := g_lo_prefix;

  /* with no weighting factor, the score for a hit is always 3.
     the weight together with rounding makes the score always 1. */
  g_weight                  constant varchar2(4) := '*10';

  -- private function, called from Init

  function CalculateBase (min_int integer, max_int integer)
      return integer is
    i          integer := 0;
    num_range  integer;
  begin
    num_range := max_int - min_int;
    -- by trial and error
    i := 1;
    while (i <= 20) loop
      if ( (i**4) > num_range ) then
        return i;
      end if;
      i := i+1;
    end loop;

    -- if we've reached here then we can't do it
    raise_application_error (-20000,
      'Cannot handle numeric range of '||to_char(num_range)||
      ' max is '||to_char(((i-1)**4)-1));
    return -1;
  end CalculateBase;

  function GetRange (min_int integer, max_int integer)
      return integer is 
    base               integer;
    trumax             integer;
    pseudo_digit_base  integer;
  begin
    base    := CalculateBase (min_int, max_int);
    pseudo_digit_base  :=   base * base;
    trumax  := pseudo_digit_base * pseudo_digit_base - 1 + min_int;
    return (trumax - min_int);
  end GetRange;

  procedure Init (p_min integer, p_max integer) is
  begin
    g_base               :=   CalculateBase(p_min, p_max);
    g_pseudo_digit_base  :=   g_base * g_base;
    g_min_integer        :=   p_min;
    g_max_integer        :=   p_max;
--    This would allow you to use the LARGEST values allowed for your base,
--    maximising the value. We choose to restrict to specified max
--    g_max_integer        :=   g_pseudo_digit_base * g_pseudo_digit_base - 1
--                               + g_min_integer;
  end init;

  function IntegerToAnyBase
    ( p_integer in integer )
      return       varchar2
  is 
  begin
    if p_integer >= 0 and p_integer <= 9
    then
      return chr ( p_integer + 48 ); /* chr(48) is '0' */
    elsif p_integer <= 35
    then
      return chr ( p_integer + 55 ); /* chr(65) is 'A' */
    else
      raise_application_error ( -20000, 
        'Friedman.IntegerToAnyBase: ' ||
        'Cannot convert ' || to_char ( p_integer ) || ' to AnyBase' );                            
    end if;
  end IntegerToAnyBase;  


  procedure IntegerToTwoPseudoDigits
    ( p_integer           in  integer,
      p_hi_pseudo_digit   out integer,
      p_lo_pseudo_digit   out integer  )
  is 
    v_hi_pseudo_digit         integer;
    v_lo_pseudo_digit         integer;
  begin
    /* we've already checked that p_integer is in g_min_integer..g_max_integer */
    
    v_hi_pseudo_digit := floor ( p_integer / g_pseudo_digit_base );
    v_lo_pseudo_digit := p_integer - ( v_hi_pseudo_digit * g_pseudo_digit_base );

    /* sanity check */
    if ( ( v_hi_pseudo_digit * g_pseudo_digit_base ) +
         ( v_lo_pseudo_digit  )
                                                       ) = p_integer
    then
      p_hi_pseudo_digit := v_hi_pseudo_digit;
      p_lo_pseudo_digit := v_lo_pseudo_digit;
      return;
    else
      raise_application_error ( -20000, 
        'Friedman.Integer: ' ||
        'Sanity check failed for '|| to_char(p_integer));                            
    end if;                                       
  end IntegerToTwoPseudoDigits;

  function IntegerToTwoCharacterCode
    ( p_integer   in integer  )
      return         varchar2
  is 
    v_2nd_decimal_digit   integer;
    v_1st_decimal_digit   integer;
  begin
    v_1st_decimal_digit := floor ( p_integer / g_base );
    v_2nd_decimal_digit := p_integer - ( v_1st_decimal_digit * g_base );

    /* sanity check */
    if ( ( v_1st_decimal_digit * g_base ) +
         ( v_2nd_decimal_digit           )   ) = p_integer
    then
      return IntegerToAnyBase ( v_1st_decimal_digit ) ||
             IntegerToAnyBase ( v_2nd_decimal_digit );
    else
      raise_application_error ( -20000, 
        'Friedman.IntegerToTwoCharacterCode: ' ||
        'Sanity check failed.');                            
    end if;                                       
  end IntegerToTwoCharacterCode;


  function EncodeInteger
    ( p_integer  in number )
      return        varchar2
  is 
    /* ensure result fits in varchar2(4000) */
    adj_integer           integer;       -- has min_value subtracted from it
    v_encoded_integer     varchar2(4000) := null;
    v_hi_pseudo_digit     integer;
    v_lo_pseudo_digit     integer;
    j                     integer;
  begin
    if p_integer < g_min_integer
    then                           
      raise_application_error ( -20000, 
        'Friedman.EncodeInteger: ' ||
        'integer value cannot be < '||to_char ( g_min_integer ) );                            
    elsif p_integer > g_max_integer
    then                           
      raise_application_error ( -20000, 
        'Friedman.EncodeInteger: ' ||
        'integer value cannot be > ' || to_char ( g_max_integer ) );                            
    end if;

    adj_integer := p_integer - g_min_integer;

    IntegerToTwoPseudoDigits ( adj_integer,
                               v_hi_pseudo_digit,
                               v_lo_pseudo_digit );
                              
    for j in 0..v_hi_pseudo_digit
    loop
      v_encoded_integer := v_encoded_integer ||
                             g_hi_prefix || IntegerToTwoCharacterCode ( j ) || ' ';
    end loop;                              
                              
    for j in 0..v_lo_pseudo_digit
    loop
      v_encoded_integer := v_encoded_integer ||
                             g_lo_prefix || IntegerToTwoCharacterCode ( j ) || ' ';
    end loop;                              
              
--insert into trace_source values (v_encoded_integer);

    return v_encoded_integer;
  end EncodeInteger;

  function EncodeDate /*____________________________________________________*/
    ( p_date      in date )
      return    varchar2
  is 
    v_date_integer        integer;
  begin
    v_date_integer := to_number ( to_char ( p_date, 'j' ) );
    if v_date_integer < g_min_integer
    then                           
      raise_application_error ( -20000, 
        'DateXform.EncodeDate: ' ||
        'Date cannot be earlier than ' ||
        to_char ( g_min_date, 'DD-MON-YYYY' ) );                            
    elsif v_date_integer > g_max_integer
    then                           
      raise_application_error ( -20000, 
        'DateXform.EncodeDate: ' ||
        'Date cannot be later than ' ||
           to_char(g_max_date, 'DD-MON-YYYY'));
    end if;
    
    return EncodeInteger ( v_date_integer );
  end EncodeDate;


  function GreaterOrEqualCriteria
    ( p_integer        in number
    ) 
      return              varchar2
  is
    v_hi_pseudo_digit     integer;
    v_lo_pseudo_digit     integer;
    v_hi_code             varchar(4);
    v_hi_code_plus_one    varchar(4);
    v_lo_code             varchar(4);
  begin 
    IntegerToTwoPseudoDigits ( p_integer,
                               v_hi_pseudo_digit,
                               v_lo_pseudo_digit );
    v_hi_code_plus_one :=
      g_hi_escaped_prefix || IntegerToTwoCharacterCode ( v_hi_pseudo_digit + 1 );
    v_hi_code :=
      g_hi_escaped_prefix || IntegerToTwoCharacterCode ( v_hi_pseudo_digit );
    v_lo_code :=
      g_lo_escaped_prefix || IntegerToTwoCharacterCode ( v_lo_pseudo_digit );

    return v_hi_code_plus_one ||
           ' | ( '            ||
           v_hi_code          ||
           ' & '              ||
           v_lo_code          ||
           ' )'                               ;
  end GreaterOrEqualCriteria;                  

  -- This function generates a contains clause
  -- the integer values are raw unadjusted numbers - do not subtract
  -- the min_value first

  function IntegerContainsCriteria
    ( p_integer        in number,
      p_other_integer  in number,
      p_operator       in varchar2
    ) 
      return              varchar2
  is
    /* ensure result fits in varchar2(4000) */
    v_contains            varchar2(4000) := null;
    v_integer             integer;
    v_other_integer       integer;
    v_hi_pseudo_digit     integer;
    v_lo_pseudo_digit     integer;    
    v_hi_code             varchar(4);
    v_hi_code_plus_one    varchar(4);
    v_lo_code             varchar(4);
    v_lo_code_plus_one    varchar(4);
  begin 
    if p_integer < g_min_integer
    then                           
      raise_application_error ( -20000, 
        'Friedman.EncodeInteger: ' ||
        'p_integer cannot be < '||to_char(g_min_integer));                            
    elsif p_integer > g_max_integer
    then                           
      raise_application_error ( -20000, 
        'Friedman.EncodeInteger: ' ||
        'p_integer cannot be > ' || to_char ( g_max_integer ) );                            
    end if;

    -- Adjust for start value
    v_integer       := p_integer       - g_min_integer;
    v_other_integer := p_other_integer - g_min_integer;

    if p_operator = 'G'
    then      

      v_contains := '( ' || GreaterOrEqualCriteria ( v_integer ) || ' )' || g_weight;

    elsif p_operator = 'L'
    then
      /* can't use NOT by itself - '00' present in all encodings */
      v_contains := '( ' || g_lo_escaped_prefix || '00 ~ ( '                                 ||
                    GreaterOrEqualCriteria ( v_integer + 1 )  ||
                    ' ) )' || g_weight;

    elsif p_operator = 'B'
    then
      v_contains := '( ( '                                         ||
                    GreaterOrEqualCriteria ( v_integer )           ||
                    ' ) ~ ( '                                      ||
                    GreaterOrEqualCriteria ( v_other_integer + 1 ) ||
                    ' ) )' || g_weight;

    else /* p_operator = 'E' */
      IntegerToTwoPseudoDigits ( v_integer,
                                 v_hi_pseudo_digit,
                                 v_lo_pseudo_digit );
      v_hi_code :=
        g_hi_escaped_prefix || IntegerToTwoCharacterCode ( v_hi_pseudo_digit );
      v_hi_code_plus_one :=
        g_hi_escaped_prefix || IntegerToTwoCharacterCode ( v_hi_pseudo_digit + 1 );
      v_lo_code :=
        g_lo_escaped_prefix || IntegerToTwoCharacterCode ( v_lo_pseudo_digit );
      v_lo_code_plus_one :=
        g_lo_escaped_prefix || IntegerToTwoCharacterCode ( v_lo_pseudo_digit + 1 );
      v_contains := '( '               ||
                    v_hi_code          ||
                    ' & '              ||
                    v_lo_code          ||
                    ' ~ '              ||
                    v_hi_code_plus_one ||
                    ' ~ '              ||
                    v_lo_code_plus_one ||
                    ' )' || g_weight;
    end if;      
      
    return v_contains;

  end IntegerContainsCriteria;

end Friedman;
/
--list
Show errors

create or replace package ctx_cd is

  procedure create_cdstore(
     cdstore_name varchar2,
     table_name   varchar2);

  procedure add_column(
     cdstore_name varchar2,
     column_name  varchar2,
     section_name varchar2 default null,
     visible      boolean  default true,
     min_int      integer  default null,
     max_int      integer  default null);

  procedure add_column(
     cdstore_name varchar2,
     column_name  varchar2,
     section_name varchar2 default null,
     visible      boolean  default true,
     min_date     date,
     max_date     date);

  procedure add_update_trigger(
     cdstore_name varchar2,
     column_name  varchar2);

  procedure drop_cdstore(
     cdstore_name  varchar2);

  function get_range (
      min_int      integer,
      max_int      integer)
    return integer;

  function get_range (
      min_date     date,
      max_date     date)
    return date;

  function int_contains
    ( cdstore_name     varchar2,
      column_name      varchar2,
      int_value        number,  /* in range g_min_integer..g_max_integer */
      other_int_value  number,  /* in range g_min_integer..g_max_integer */
      operator         varchar2 /* 'E' ==>  = p_integer 
                                   'G' ==> >= p_integer
                                   'L' ==> <= p_integer
                                   'B' ==> >= p_integer and
                                           <= p_other_integer */
    ) 
      return              varchar2; /* guaranteed to fit in varchar2(4000) */

  function date_contains
    ( cdstore_name     varchar2,
      column_name      varchar2,
      date_value       date,    /* in range g_min_integer..g_max_integer */
      other_date_value date,    /* in range g_min_integer..g_max_integer */
      operator         varchar2 /* 'E' ==>  = p_integer 
                                   'G' ==> >= p_integer
                                   'L' ==> <= p_integer
                                   'B' ==> >= p_integer and
                                           <= p_other_integer */
    ) 
      return              varchar2; /* guaranteed to fit in varchar2(4000) */

end;
/
-- list
show errors

create or replace package body ctx_cd is

  -- internal functions

  function identifier_is_valid (the_name in varchar2)
    return boolean is
  p integer;
  disallowed varchar2(80) := ' !"%^&*()+={}[]@~''#?/<>,.|\`';
  c varchar2(1);

  begin
    for p in 1 .. length(the_name) loop
      c := substr(the_name, p, 1);
      if (instr (disallowed, c) > 0) then
         return false;
      end if;
    end loop;
    return true;
  end;
 
  procedure do_dynamic_setup (
     cdname varchar2, username varchar2, tablename varchar2) is
    proc_buffer varchar2(32767);

    type vch_tab is  table of varchar2(30) index by binary_integer;
    type int_tab is  table of integer      index by binary_integer;

    col_names      vch_tab;
    sec_names      vch_tab;
    types          vch_tab;
    visibles       vch_tab;
    mins           int_tab;
    maxs           int_tab;

    v_id           integer;

    cntr           integer := 0;
    char_cnt       integer := 0;
    clob_cnt       integer := 0;
    date_cnt        integer := 0;
    int_cnt        integer := 0;
    col_cnt        integer := 0;

    cursor cols (cname varchar2) is 
      SELECT   cdstore_id, column_name, section_name, visible, 
               col_type, min_int, max_int
      FROM     ctx_user_cdstore_cols
      WHERE    cdstore_name = cname
      ORDER BY col_type;
   
    select_clause  varchar2(2000);
    into_clause    varchar2(2000);
    comma          varchar2(2);

  begin 

    open cols (cdname);
    cntr := 1;
    loop
      fetch cols into 
          v_id, col_names(cntr), sec_names(cntr), visibles(cntr), types(cntr),
          mins(cntr), maxs(cntr);

      exit when cols%notfound;

      if    (types(cntr) = 'CHAR'  ) then
         char_cnt := char_cnt + 1;
      elsif (types(cntr) = 'CLOB'  ) then
         clob_cnt := clob_cnt + 1;
      elsif (types(cntr) = 'DATE'  ) then
         date_cnt := date_cnt + 1;
      elsif (types(cntr) = 'NUMBER') then
         int_cnt := int_cnt + 1;
      else
         raise_application_error(-20000, 'illegal value for column type');
      end if;
        
      cntr := cntr+1;

    end loop;
    col_cnt := cntr-1;  -- cntr gets incremented one too many times

    -- Must have at least one column defined to continue

    if (col_cnt < 1) then
      raise_application_error (-20000, 
        'No columns defined for concatenated datastore ' || cdname);
    end if;

    -- Assertion to check column count
    if (char_cnt + clob_cnt + date_cnt + int_cnt != col_cnt) then
      raise_application_error (-20000, 
         'internal error: column count mismatch');
    end if;

    proc_buffer :=
    'create or replace procedure cdstore$'||to_char(v_id)|| chr(10) ||
    '  (rid in rowid,'                                   || chr(10) ||
    '  tlob in out nocopy clob ) is'                     || chr(10) ||
    '  v_length                       integer;'          || chr(10) ||
    '  v_buffer                       varchar2(4000);'   || chr(10);

    for cntr in 1..col_cnt loop

      proc_buffer := proc_buffer ||
        '  tag' || cntr || ' varchar2(30) := ''' || 
        sec_names(cntr) || ''';' || chr(10);

    end loop;    

    for cntr in 1 .. char_cnt loop
      proc_buffer := proc_buffer || 
        '  vvc' || to_char(cntr) || ' varchar2(32767);' || chr(10);
    end loop;

    for cntr in 1 .. clob_cnt loop
      proc_buffer := proc_buffer ||
        '  vclob' || to_char(cntr) || ' clob;' || chr(10);
    end loop;

    for cntr in 1 .. date_cnt loop
      proc_buffer := proc_buffer ||
        '  vdate' || to_char(cntr) || ' date;' || chr(10);
    end loop;

    for cntr in 1 .. int_cnt loop
      proc_buffer := proc_buffer ||
        '  vint' || to_char(cntr) || ' integer;' || chr(10);
    end loop;

    proc_buffer := proc_buffer || '  begin' || chr(10);
 
    -- Generate the select statement

    select_clause := '';
    into_clause   := '';
    comma         := '';

    select_clause := ' SELECT ';
    into_clause   := ' INTO ';

    for cntr in 1 .. char_cnt loop
      select_clause := select_clause || comma || col_names(cntr);
      into_clause   := into_clause   || comma || 'vvc' || to_char(cntr);
      comma := ', ';
    end loop;

    for cntr in 1 .. clob_cnt loop
      select_clause := select_clause || comma || col_names(cntr+char_cnt);
      into_clause   := into_clause   || comma || 'vclob' || to_char(cntr);
      comma := ', ';
    end loop;

    for cntr in 1 .. date_cnt loop
      select_clause := select_clause || comma || col_names(cntr+char_cnt+clob_cnt);
      into_clause   := into_clause   || comma || 'vdate' || to_char(cntr);
      comma := ', ';
    end loop;

    for cntr in 1 .. int_cnt loop
      select_clause := select_clause || comma || col_names(cntr+char_cnt+clob_cnt+date_cnt);
      into_clause   := into_clause   || comma || 'vint' || to_char(cntr);
      comma := ', ';
    end loop;

    proc_buffer := proc_buffer || select_clause || into_clause || chr(10) ||
    ' from ' || username || '.' || tablename                   || chr(10) ||
    ' where rowid = rid;'                                      || chr(10) ||
    '  v_buffer := '''' '                                      || chr(10);

    for cntr in 1 .. char_cnt loop
      proc_buffer := proc_buffer ||  
        ' || ' ||
        '          ''<''  || tag' || cntr || ' || ''>'' ||' || chr(10) ||
        '              vvc' || cntr || ' ||'                    || chr(10) ||
        '              ''</'' || tag' || cntr || ' || ''>'' || chr(10)' || chr(10);
    end loop;

    proc_buffer := proc_buffer || ';'       || chr(10) ||
    ''                                      || chr(10) ||
    '  v_length := length ( v_buffer );'    || chr(10) ||
    ''                                      || chr(10) ||
    '  Dbms_Lob.Trim'                       || chr(10) ||
    '    ('                                 || chr(10) ||
    '      lob_loc        => tlob,'         || chr(10) ||
    '      newlen         => 0'             || chr(10) ||
    '    );'                                || chr(10) ||
    ''                                      || chr(10);
    
    if (char_cnt > 0) then
      proc_buffer := proc_buffer ||
      '  Dbms_Lob.Write'                    || chr(10) ||
      '    ('                               || chr(10) ||
      '      lob_loc        => tlob,'       || chr(10) ||
      '      amount         => v_length,'   || chr(10) ||
      '      offset         => 1,'          || chr(10) ||
      '      buffer         => v_buffer'    || chr(10) ||
      '    );'                              || chr(10);
    end if;

    for cntr in 1..clob_cnt loop
      proc_buffer := proc_buffer ||
        '  Dbms_Lob.WriteAppend'                           || chr(10) ||
        '    ('                                            || chr(10) ||
        '      lob_loc  => tlob,'                          || chr(10) ||
        '      amount   => length ( ''<''' || 
        '|| tag' || to_char(char_cnt+cntr) || '||''>'' || chr(10)),' || chr(10) ||
        '      buffer   => ''<''' || 
        '|| tag' || to_char(char_cnt+cntr) || '||''>'' || chr(10)'    || chr(10) ||
        '    );'                                           || chr(10) ||
        '  Dbms_Lob.Copy'                                  || chr(10) ||
        '    ('                                            || chr(10) ||
        '      dest_lob      => tlob,'                     || chr(10) ||
        '      src_lob       => vclob'|| cntr || ','       || chr(10) ||
        '      amount        => Dbms_Lob.GetLength (vclob' || cntr ||
        '),'                                               || chr(10) ||
        '      dest_offset   => Dbms_Lob.GetLength (tlob)+1,'|| chr(10) ||
        '      src_offset    => 1'                         || chr(10) ||
        '    );'                                           || chr(10) ||
        ''                                                 || chr(10) ||
        '  Dbms_Lob.WriteAppend'                           || chr(10) ||
        '    ('                                            || chr(10) ||
        '      lob_loc  => tlob,'                          || chr(10) ||
        '      amount   => length ( ''</''' || 
        '|| tag' || to_char(char_cnt+cntr) || '||''>'' || chr(10)),' || chr(10) ||
        '      buffer   => ''</''' || 
        '|| tag' || to_char(char_cnt+cntr) || '||''>'' || chr(10)'    || chr(10) ||
        '    );'                                       || chr(10);
    end loop;

    -- Dates via Friedman algorithm

    for cntr in 1..date_cnt loop

      proc_buffer := proc_buffer ||
        '  Friedman.Init(' || mins(cntr+char_cnt+clob_cnt) || ', ''' || 
        maxs(cntr+char_cnt+clob_cnt) || ''');' || chr(10);

      proc_buffer := proc_buffer ||
        '  v_buffer := '''' '                               || chr(10) ||
        ' || ' ||
        '          ''<''  || tag' || to_char(char_cnt+clob_cnt+cntr) || ' || ''>'' ||' || chr(10) ||
        '              Friedman.EncodeDate(vdate' || cntr || ') ||'  || chr(10) ||
        '          ''</'' || tag' || to_char(char_cnt+clob_cnt+cntr) || ' || ''>'' || chr(10);' || chr(10) ||
        '  v_length := length ( v_buffer );'                || chr(10) ||
        ''                                                  || chr(10) ||
        -- Next line for debugging. Use very carefully due to 255 char limit 
        --  in dbms_output. Indexing will FAIL if longer. Check ctx_user_index_errors
        -- '  dbms_output.put_line( v_buffer );'               || chr(10) ||
        '  Dbms_Lob.WriteAppend'                            || chr(10) ||
        '    ('                                             || chr(10) ||
        '      lob_loc  => tlob,'                           || chr(10) ||
        '      amount   => v_length,'                       || chr(10) ||
        '      buffer   => v_buffer'                        || chr(10) ||
        '    );'                                            || chr(10) ||
        '  Dbms_Lob.WriteAppend'                            || chr(10) ||
        '    ('                                             || chr(10) ||
        '      lob_loc  => tlob,'                           || chr(10) ||
        '      amount   => length ( ''<''' || 
        '|| tag' || to_char(char_cnt+clob_cnt+cntr) || '||''>'' || chr(10)),' || chr(10) ||
        '      buffer   => ''<''' || 
        '|| tag' || to_char(char_cnt+clob_cnt+cntr) || '||''>'' || chr(10)'    || chr(10) ||
        '    );'                                           || chr(10);
    end loop;

    -- Integers via Friedman algorithm

    for cntr in 1..int_cnt loop

      proc_buffer := proc_buffer ||
        '  Friedman.Init(' || mins(cntr+char_cnt+clob_cnt+date_cnt) || ', ' || 
        maxs(cntr+char_cnt+clob_cnt+date_cnt) || ');' || chr(10);

      proc_buffer := proc_buffer ||
        '  v_buffer := '''' '                               || chr(10) ||
        ' || ' ||
        '          ''<''  || tag' || to_char(char_cnt+clob_cnt+date_cnt+cntr) || ' || ''>'' ||' || chr(10) ||
        '              Friedman.EncodeInteger(vint' || cntr || ') ||'  || chr(10) ||
        '          ''</'' || tag' || to_char(char_cnt+clob_cnt+date_cnt+cntr) || ' || ''>'' || chr(10);' || chr(10) ||
        '  v_length := length ( v_buffer );'                || chr(10) ||
        ''                                                  || chr(10) ||
        --        '  insert into trace_source values ( v_buffer ); ' || chr(10) ||
        '  Dbms_Lob.WriteAppend'                            || chr(10) ||
        '    ('                                             || chr(10) ||
        '      lob_loc  => tlob,'                           || chr(10) ||
        '      amount   => v_length,'                       || chr(10) ||
        '      buffer   => v_buffer'                        || chr(10) ||
        '    );'                                            || chr(10) ||
        '  Dbms_Lob.WriteAppend'                            || chr(10) ||
        '    ('                                             || chr(10) ||
        '      lob_loc  => tlob,'                           || chr(10) ||
        '      amount   => length ( ''<''' || 
        '|| tag' || to_char(char_cnt+clob_cnt+date_cnt+cntr) || '||''>'' || chr(10)),' || chr(10) ||
        '      buffer   => ''<''' || 
        '|| tag' || to_char(char_cnt+clob_cnt+date_cnt+cntr) || '||''>'' || chr(10)'    || chr(10) ||
        '    );'                                           || chr(10);
    end loop;

    proc_buffer := proc_buffer || 'end;';  

-- FOR DEBUGGING: Needs table CREATE TABLE TRACE_SOURCE (PROC_BUFFER CLOB)
-- This allows you to inspect the generated procedure from SQL*Plus
-- remember to SET LONG 20000 or similar

--    delete from trace_source;
--    insert into trace_source values (proc_buffer);

-- END DEBUGGING CODE
    
    execute immediate proc_buffer;
  
    execute immediate 
       ('grant execute on cdstore$' || to_char(v_id) || ' to ' || username);

    -- Create the datastore (delete first but ignore "does not exist" err)
    begin
      execute immediate
       ('begin ctx_ddl.drop_preference(''' || cdname || ''') ; end ;');
    exception
      when others then
        null;
    end;

    execute immediate
       ('begin '                                                 ||
          'ctx_ddl.create_preference '                           || 
          '( ''' || cdname || ''', ''user_datastore'' ); '   ||
          'ctx_ddl.set_attribute '                               || 
          '( ''' || cdname || ''', ''procedure'',''cdstore$'||
          to_char(v_id) ||''' ); end;');

  -- Now create the section group and sections

  -- Create the section group
  -- Delete it first, ignoring errors if it doesn't exist
  begin
    execute immediate (
      'begin ctx_ddl.drop_section_group '        ||
        '(group_name  => ''' || cdname || ''') ; end ; ');
  exception
    when others then
      null;
  end;

  execute immediate (
    'begin ctx_ddl.create_section_group ('     ||
      'group_name   => ''' || cdname || ''', ' ||
      'group_type   => ''basic_section_group'') ; end ; ');

  for cntr in 1 .. col_cnt loop
    -- No section tags if sec_names(col) is empty
    if (length(sec_names(cntr)) > 0) then
      proc_buffer := 
        'begin ctx_ddl.add_field_section ('                  || chr(10) ||
        '  group_name   => ''' || cdname           || ''','  || chr(10) ||
        '  section_name => ''' || sec_names(cntr)  || ''','  || chr(10) ||
        '  tag          => ''' || sec_names(cntr)  || ''','  || chr(10);
      if (visibles(cntr) = 'Y') then
        proc_buffer := proc_buffer || '  visible      => true ) ; end ; ';
      else
        proc_buffer := proc_buffer || '  visible      => false ) ; end ; ';
      end if;
-- DEBUG CODE
--      insert into trace_source values (proc_buffer);
-- END DEBUG CODE
      execute immediate (proc_buffer);
    end if;
  end loop;
  end do_dynamic_setup;

  -- Public functions

  function get_range (
      min_int      integer,
      max_int      integer)
    return integer is
  begin
    return Friedman.getRange (min_int, max_int);
  end;

  function get_range (
      min_date     date,
      max_date     date)
    return date is
    int1 integer;
    int2 integer;
    int3 integer;
  begin
    int1 := to_number( to_char(min_date, 'j') );
    int2 := to_number( to_char(max_date, 'j') );

    int3 := Friedman.getRange (int1, int2);
    return to_date (int3, 'j');
  end;

  procedure do_create_cdstore(
     cdstore_name  varchar2) is
    the_name varchar2(30) default 'testprocedure';
    proc_buffer     varchar2(32767);
    cnt             integer;
    l_cdstore_name  varchar2(30);
    l_user          varchar2(30);
    tab             varchar2(30);
  begin

   l_cdstore_name := upper(cdstore_name);

   -- First check that the table does exist. Otherwise we
   -- will get errors when trying to compile the dynamic
   -- proc that references it

   -- get username (used later)
   select user into l_user
   from dual;

   -- get table name
   begin
     select table_name into tab
       from ctx_user_cdstores
       where cdstore_name = l_cdstore_name;
   exception
     when no_data_found then
       raise_application_error (-20000,
         'concatenated datastore '||l_cdstore_name||' does not exist');
   end;

   -- check data dictionary
   select count(*) into cnt
   from all_tables
   where owner = user
   and table_name = tab;

   if (cnt = 0) then
     raise_application_error (-20000,
        'table '||tab||' does not exist');
   end if;

   -- table verified. Create the dynamic procedure

   do_dynamic_setup (l_cdstore_name, l_user, tab);

  end do_create_cdstore;

  procedure create_cdstore(
     cdstore_name varchar2,
     table_name   varchar2) is
    cnt number;
    l_cdstore varchar2(30);
    l_table_name varchar2(30);
  begin
    -- copy args to local vars to avoid confusion with column names
    l_cdstore    := upper(cdstore_name);
    l_table_name := upper(table_name);

    -- Check name is valid
    if (not (identifier_is_valid(l_cdstore))) then
      raise_application_error (-20000, 
        'illegal characters in concatenated datastore name '|| l_cdstore);
    end if;

    -- check data dictionary to make sure table exists

    select count(*) into cnt
    from   all_tables
    where  owner = user
    and    table_name = l_table_name;
    
    if (cnt = 0) then
        raise_application_error (-20000,
          'table '|| l_table_name ||' does not exist');
    end if;

    -- check this datastore hasn't already been defined

    select count(*) into cnt
    from   ctx_user_cdstores
    where  cdstore_name = l_cdstore;

    if (cnt > 0) then
      raise_application_error (-20000,
         'concatenated datastore '||l_cdstore||' already exists');
    end if;

    -- Get a reference number for this concat dstore
    select ctx_cdstore_seq.nextval
    into cnt
    from dual;
    
    insert into ctx_cdstores (
      cdstore_id, cdstore_name, owner, table_name)
      values (
      cnt, l_cdstore, user, l_table_name);

  end create_cdstore;

  procedure add_update_trigger(
     cdstore_name  varchar2,
     column_name   varchar2) is
    id             number;
    l_name         varchar2(30);
    l_table_name   varchar2(30);
    l_owner        varchar2(30);
    l_col_name     varchar2(30);
    l_col_type     varchar2(30);
 
    sql_stmt       varchar2(2000);

  begin
    -- copy args to local vars to avoid confusion with col names
    l_name     := upper(cdstore_name);
    l_col_name := upper(column_name);

    -- Find column type   
    --      BLOB, BFILE, RAW, LONG RAW - Not allowed
    --      CLOB - Unlimited size, handled automatically
    --      All Others (including LONG) max 32767 chars

    begin
      select c.data_type, t.owner, t.table_name
      into   l_col_type, l_owner, l_table_name
      from   all_tables t, all_tab_columns c, ctx_user_cdstores d
      where  t.owner        = c.owner 
      and    t.owner        = user
      and    t.table_name   = c.table_name
      and    t.table_name   = d.table_name
      and    d.cdstore_name = l_name
      and    c.column_name  = l_col_name;
    exception
      when no_data_found then
        raise_application_error (-20000,
          'no such column '||l_col_name||' in table');
      when others then
        raise_application_error (-20000,
          'Oracle error looking for column');
    end;

    if (l_col_type = 'CLOB' or l_col_type = 'BLOB' or 
        l_col_type = 'RAW' or l_col_type = 'LONG' or
        l_col_type = 'LONG RAW' or l_col_type = 'BFILE') then
      raise_application_error (-20000,
        'Cannot create update trigger on LONG, CLOB or binary data types');
    end if;

    -- Anything other than CLOB should be treated as CHAR
    if (l_col_type != 'CLOB') then
      l_col_type := 'CHAR';
    end if;
  
    sql_stmt := 
      'create or replace trigger ' || 
      l_owner || '.' || l_name   || chr(10) ||
      ' before update on ' ||
      l_owner || '.' || l_table_name           || chr(10) ||
      ' for each row'                          || chr(10) ||
      ' begin'                                 || chr(10) ||
      '   :new.' || l_col_name || ':=' ||
      ' :old.' || l_col_name || ';'  || chr(10) ||
      ' end;';

--    insert into trace_source values (sql_stmt);

    execute immediate (sql_stmt);
 
  end add_update_trigger;

  procedure add_column(
     cdstore_name varchar2,
     column_name  varchar2,
     section_name varchar2 default null,
     visible      boolean  default true,
     min_date     date,
     max_date     date) is

    id number;
    l_name varchar2(30);
    l_col_name     varchar2(30);
    l_sec_name     varchar2(30);
    l_visible      char(1);
    l_col_type     varchar2(30);
    l_min_date     date;
    l_max_date     date;
    l_base         integer;
  begin
    -- copy args to local vars to avoid confusion with col names
    l_name       := upper(cdstore_name);
    l_col_name   := upper(column_name);
    l_min_date   := min_date;
    l_max_date   := max_date;
    if (visible) then 
      l_visible  := 'Y';
    else
      l_visible  := 'N';
    end if;

    -- Check values

    if max_date < min_date then
      raise_application_error (-20000,
        'MAX_DATE cannot be earlier than MIN_DATE');
    end if;

    -- Find column type   
    -- Can only be a DATE if min_date or max_date specified

    begin
      select data_type
      into   l_col_type
      from   all_tables t, all_tab_columns c, ctx_user_cdstores d
      where  t.owner        = c.owner 
      and    t.owner        = user
      and    t.table_name   = c.table_name
      and    t.table_name   = d.table_name
      and    d.cdstore_name = l_name
      and    c.column_name  = l_col_name;
    exception
      when no_data_found then
        raise_application_error (-20000,
          'no such column '||l_col_name||' in table');
    end;

    if (l_col_type != 'DATE') then
      raise_application_error (-20000,
        'MAX_DATE and MIN_DATE may only be specified for DATE columns');
    end if;

    -- If it's a date column we must have max and min values
    if ( l_min_date is null or l_max_date is null) then
      raise_application_error (-20000,
        'date columns must specify MAX_DATE and MIN_DATE values');
    end if;
    
    -- If section name is null, set it to the column name.

    if (section_name is null) then
      l_sec_name := l_col_name;
    else 
      l_sec_name := upper(section_name);
    end if;

    -- Validate that cdstore exists

    begin
      select cdstore_id into id
      from ctx_cdstores
      where owner = user
      and cdstore_name = l_name;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'concatenated datastore ' || l_name || ' does not exist');
    end;

    -- Validated that cdstore exists OK
    -- now store col data

    insert into ctx_cdstore_cols (
      cdstore_id, column_name, section_name, visible, col_type, min_int, max_int, min_date, max_date )
     values 
      (
      id, l_col_name, l_sec_name, l_visible, l_col_type, 
      to_number( to_char(l_min_date, 'j') ), 
      to_number( to_char(l_max_date, 'j') ),
      l_min_date,
      l_max_date
      );

    -- Now do all the creation of proc, preferences, etc.
    -- Note that this is done for every column definition, which
    -- is somewhat wasteful, but this is not performance critical
    -- and it allows us to better match SECTION_GROUP syntax
   
    do_create_cdstore(l_name);

  end;

  procedure add_column(
     cdstore_name varchar2,
     column_name  varchar2,
     section_name varchar2 default null,
     visible      boolean  default true,
     min_int      integer default null,
     max_int      integer default null) is

    id number;
    l_name varchar2(30);
    l_col_name     varchar2(30);
    l_sec_name     varchar2(30);
    l_visible      char(1);
    l_col_type     varchar2(30);
    l_min_int      integer;
    l_max_int      integer;
    l_base         integer;
  begin
    -- copy args to local vars to avoid confusion with col names
    l_name     := upper(cdstore_name);
    l_col_name := upper(column_name);
    l_min_int  := min_int;
    l_max_int  := max_int;
    if (visible) then 
      l_visible  := 'Y';
    else
      l_visible  := 'N';
    end if;

    -- Check values

    if max_int < min_int then
      raise_application_error (-20000,
        'MAX_INT cannot be less than MIN_INT');
    end if;

    -- Find column type   
    --      BLOB, BFILE, RAW, LONG RAW - Not allowed
    --      CLOB - Unlimited size, handled automatically
    --      All Others (including LONG) max 32767 chars

    begin
      select data_type
      into   l_col_type
      from   all_tables t, all_tab_columns c, ctx_user_cdstores d
      where  t.owner        = c.owner 
      and    t.owner        = user
      and    t.table_name   = c.table_name
      and    t.table_name   = d.table_name
      and    d.cdstore_name = l_name
      and    c.column_name  = l_col_name;
    exception
      when no_data_found then
        raise_application_error (-20000,
          'no such column '||l_col_name||' in table');
    end;

    if (l_col_type = 'BLOB' OR l_col_type = 'RAW' or
        l_col_type = 'LONG RAW' or l_col_type = 'BFILE') then
      raise_application_error (-20000,
        'BLOB, BFILE and RAW column types not supported in this version');
    end if;

    -- Anything other than CLOB, NUMBER should be treated as CHAR
    --  (date cols with specified max and min will not be dealt with here)
    if (l_col_type != 'CLOB' and l_col_type != 'NUMBER') then
      l_col_type := 'CHAR';
    end if;

    -- Check value for col_type - only support CHAR and CLOB
    -- at this time

    if (l_col_type != 'CHAR' and l_col_type != 'CLOB' and 
        l_col_type != 'DATE' and l_col_type != 'NUMBER') then
      raise_application_error (-20000,
        'col_type ' || l_col_type || ' invalid - use CHAR or CLOB');
    end if;

    -- Check max and min values for numeric columns

    if (l_col_type = 'NUMBER') then

      if ( (l_min_int is not null and l_max_int is null) or
           (l_max_int is not null and l_min_int is null) ) then
        raise_application_error (-20000,
          'must specify both MAX_INT and MIN_INT if either is used');
      end if;

      -- Only use Friedman algorithm if min and max specified

      if ( l_min_int is null) then

        -- If min and max not specified, treat col as CHAR
        l_col_type := 'CHAR';

      end if;

    end if;

    -- If section name is null, set it to the column name.

    if (section_name is null) then
      l_sec_name := l_col_name;
    else 
      l_sec_name := upper(section_name);
    end if;

    -- Validate that cdstore exists

    begin
      select cdstore_id into id
      from ctx_cdstores
      where owner = user
      and cdstore_name = l_name;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'concatenated datastore ' || l_name || ' does not exist');
    end;

    -- Validated that cdstore exists OK
    -- now store col data

    insert into ctx_cdstore_cols (
      cdstore_id, column_name, section_name, visible, col_type, min_int, max_int)
     values (
      id, l_col_name, l_sec_name, l_visible, l_col_type, l_min_int, l_max_int);

    -- Now do all the creation of proc, preferences, etc.
    -- Note that this is done for every column definition, which
    -- is somewhat wasteful, but this is not performance critical
    -- and it allows us to better match SECTION_GROUP syntax
   
    do_create_cdstore(l_name);

  end add_column;

  procedure drop_cdstore(
     cdstore_name varchar2) is
    id              number;
    l_name          varchar2(30);
    no_such_object  exception;
    pragma exception_init(no_such_object, -4043);
  begin
    begin
      l_name := upper(cdstore_name);
      select cdstore_id into id
      from ctx_cdstores
      where owner = user
      and cdstore_name = l_name;

      delete from ctx_cdstores
      where cdstore_id = id;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'concatenated datastore '||l_name||' does not exist');
    end;

    -- No data found is acceptable for this part

    delete from ctx_cdstore_cols
    where cdstore_id = id;

    -- drop the preference if it exists
    begin
      execute immediate
         ('begin ctx_ddl.drop_preference(''' || l_name || ''') ; end ;');
    exception
      when others then
        null;
    end;

    -- drop the procedure
    begin
      execute immediate
        ('drop procedure '||l_name);
    exception
      when no_such_object then
        null;
    end;

    -- Drop the section group
    begin
      execute immediate (
        'begin ctx_ddl.drop_section_group '        ||
          '(group_name  => ''' || l_name || ''') ; end ; ');
    exception
      when others then
        null;
    end;

  exception
    when no_data_found then
      null;
  end;

  function int_contains
    ( cdstore_name     varchar2,
      column_name      varchar2,
      int_value        number,  /* in range g_min_integer..g_max_integer */
      other_int_value  number,  /* in range g_min_integer..g_max_integer */
      operator         varchar2 /* 'E' ==>  = p_integer 
                                   'G' ==> >= p_integer
                                   'L' ==> <= p_integer
                                   'B' ==> >= p_integer and
                                           <= p_other_integer */
    ) 
      return              varchar2  /* guaranteed to fit in varchar2(4000) */
  is
    l_name             varchar2(30);
    l_col_name         varchar2(30);
    l_id               integer;
    l_int_value        integer;
    l_other_int_value  integer;
    l_min_int          integer;
    l_max_int          integer;
    l_section_name     varchar2(30);
    retstr             varchar2(2000);
  begin
    l_name            := upper(cdstore_name);
    l_col_name        := upper(column_name);
    l_int_value       := int_value;
    l_other_int_value := other_int_value;

    if l_other_int_value < int_value then
      raise_application_error (-20000,
        'OTHER_INT_VALUE cannot be less than INT_VALUE');
    end if;

    begin
      select cdstore_id into l_id
      from   ctx_cdstores
      where  owner = user
      and    cdstore_name = l_name;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'concatenated datastore '||l_name||' does not exist');
    end;

    begin
      select min_int, max_int, section_name
      into   l_min_int, l_max_int, l_section_name
      from   ctx_cdstore_cols
      where  cdstore_id = l_id
      and    column_name = l_col_name;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'No column '|| l_col_name || ' in '|| l_name );
    end;

    -- Check values in range. If out of range, processing depends
    --   on comparison operator. It is quite legal to search for out
    --   of range values, we need to either set them to max/min, or
    --   cause the search to always fail for this component

    if l_int_value < l_min_int then
      if operator = 'G' or operator = 'B' then
        l_int_value := l_min_int;
      elsif operator = 'L' or operator = 'E' then
        -- never true
        l_int_value := -1;
      end if;
    end if;

    if l_int_value > l_max_int then
      if operator = 'L' then
        l_int_value := l_max_int;
      elsif operator = 'L' or operator = 'E' or operator = 'B' then
        -- never true
        l_int_value := -1;
      end if;
    end if;

    -- l_other_int_value only relevent to 'B'

    if l_other_int_value > l_max_int then
       l_other_int_value := l_max_int;
    end if;

    if l_other_int_value < l_min_int then
       l_int_value := -1;
    end if;

    -- Do Friedman unless l_int_value is -1 : impossible out-of-range value
    if (l_int_value != -1) then 
      Friedman.Init(l_min_int, l_max_int);
      retstr := Friedman.IntegerContainsCriteria 
          (l_int_value, l_other_int_value, operator);
    else
      retstr := 'HZZ';    -- will never be found
    end if;

    if (l_section_name is not null and length(l_section_name) > 0) then
      retstr := '( (' || retstr || ') WITHIN {' || l_section_name || '} )';
    end if;

    return retstr;

  end int_contains;


  function date_contains
    ( cdstore_name     varchar2,
      column_name      varchar2,
      date_value       date,    /* the date for 'E', 'G', 'L'*/
      other_date_value date,    /* the other date 'B' */
      operator         varchar2 /* 'E' ==>  = p_integer 
                                   'G' ==> >= p_integer
                                   'L' ==> <= p_integer
                                   'B' ==> >= p_integer and
                                           <= p_other_integer */
    ) 
      return              varchar2  /* guaranteed to fit in varchar2(4000) */
  is
    l_name             varchar2(30);
    l_col_name         varchar2(30);
    l_id               integer;
    l_date_value       date;
    l_other_date_value date;
    l_min_date         date;
    l_max_date         date;
    l_section_name     varchar2(30);
    j_value            integer;
    j_other_value      integer;
    l_min_int          integer;
    l_max_int          integer;
    retstr             varchar2(2000);
  begin
    l_name            := upper(cdstore_name);
    l_col_name        := upper(column_name);
    l_date_value       := date_value;
    l_other_date_value := other_date_value;

    if l_other_date_value < date_value then
      raise_application_error (-20000,
        'OTHER_DATE_VALUE cannot be earlier than DATE_VALUE');
    end if;

    begin
      select cdstore_id into l_id
      from   ctx_cdstores
      where  owner = user
      and    cdstore_name = l_name;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'concatenated datastore '||l_name||' does not exist');
    end;

    begin
      select min_date, max_date, section_name
      into   l_min_date, l_max_date, l_section_name
      from   ctx_cdstore_cols
      where  cdstore_id = l_id
      and    column_name = l_col_name;

    exception
      when no_data_found
      then
        raise_application_error
           (-20000, 'No column '|| l_col_name || ' in '|| l_name );
    end;

    -- Get Julian (integer) dates

    j_value       := to_number (to_char (date_value,       'j') );
    j_other_value := to_number (to_char (other_date_value, 'j') );
    l_min_int     := to_number (to_char (l_min_date,       'j') );
    l_max_int     := to_number (to_char (l_max_date,       'j') );

    -- Check values in range. If out of range, processing depends
    --   on comparison operator. It is quite legal to search for out
    --   of range values, we need to either set them to max/min, or
    --   cause the search to always fail for this component

    if l_date_value < l_min_date then
      if operator = 'G' or operator = 'B' then
        l_date_value := l_min_date;
      elsif operator = 'L' or operator = 'E' then
        -- never true
        j_value := -1;
      end if;
    end if;

    if l_date_value > l_max_date then
      if operator = 'L' then
        l_date_value := l_max_date;
      elsif operator = 'L' or operator = 'E' or operator = 'B' then
        -- never true
        j_value := -1;
      end if;
    end if;

    -- l_other_date_value only relevent to 'B'

    if l_other_date_value > l_max_date then
       l_other_date_value := l_max_date;
    end if;

    if l_other_date_value < l_min_date then
       j_value := -1;
    end if;

    -- Do Friedman unless j_value is -1 : impossible out-of-range value
    if (j_value != -1) then 
      Friedman.Init(l_min_int, l_max_int);
      retstr := Friedman.IntegerContainsCriteria 
          (j_value, j_other_value, operator);
    else
      retstr := 'HZZ';    -- will never be found
    end if;

    if (l_section_name is not null and length(l_section_name) > 0) then
      retstr := '( (' || retstr || ') WITHIN {' || l_section_name || '} )';
    end if;

    return retstr;

  end date_contains;

end;
/
-- list
show errors

grant execute on ctx_cd to ctxapp;
grant execute on Friedman to ctxapp;
drop public synonym ctx_cd;
create public synonym ctx_cd for ctxsys.ctx_cd;

