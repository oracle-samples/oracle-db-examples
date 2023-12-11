--------------------------------------------------------------------------------------
-- K-gram test
--------------------------------------------------------------------------------------
-- This script needs to be run in SQL*Plus by a user with CTXAPP role
--------------------------------------------------------------------------------------
-- this script creates a user datastore which generates K-grams for the text index
-- these K-grams can be used for faster "double-truncated" searches
-- for example if K = 3 and the user searches for %dan% then would simply search for
--   'dan within kg'
-- if the user searches for %danny% we would need to search for 
--   'dan ann nny within kg'
--------------------------------------------------------------------------------------
-- Roger Ford roger.ford@oracle.com May 2011
--------------------------------------------------------------------------------------

---------------------------------------------------------------------------
--  K_LENGTH defines the size of the K-Gram
--  This is the MINIMUM length of substring that may be searched for
--  if you set K_LENGTH=2 then you can search for %AB%, %ABC%, %ABCD% etc.
--  if you set K_LENGTH=3 then you can only search for  %ABC%, %ABCD% etc.
----------------------------------------------------------------------------

DEFINE K_LENGTH=3

----------------------------------------------------------------------------
--  Larger values of K are more efficient for indexing and queries
--  An enhancement to the query helper script would be to use wild cards where needed
--  eg if K=3 and the user wants to search for %AB% we would simply transform
--  it to 'AB% within kg'
----------------------------------------------------------------------------

drop table testtable;

create table testtable (text varchar2(2000));

insert into testtable values ('vic moore');
insert into testtable values ('roger ford');
insert into testtable values ('winston churchill');
insert into testtable values ('napoleon bonaparte');
insert into testtable values ('peter the pole');
insert into testtable values ('spolek polinski');

-- K-Gram user datastore
-- transforms "the quick brown fox jumps over the lazy dog" into
-- "the quick brown fox jumps over the lazy dog <kg>the qui uic ick bro row own fox jum ump mps ove ver the laz azy dog</kg>"

-- EXPECTATIONS

-- the text to be indexed is in the text column (VARCHAR2) of a table called testtable

-- LIMITATION

-- the maximum length of the encoded output string is 32K-1

create or replace procedure kgram_userds 
     (rid in rowid, tlob in out nocopy clob) is 
     v_text varchar2(4000);

     work varchar2(32767);    
                          
     K number := &K_LENGTH;


begin 

     select text into v_text from testtable where rowid = rid;

     -- add the untransformed text first
     tlob := v_text;

     -- add leading tag
     tlob := tlob || ' <kg>';

     work := v_text;

     -- replace all non-alphanumeric strings with a single space
     work := regexp_replace(work, '[^A-Za-z0-0]+', ' ');

     -- remove leading and trailing spaces
     work := regexp_replace(work, '^ ', ' ');
     work := regexp_replace(work, ' $', ' ');

     work := kg_split_string(work, K);

     tlob := tlob || work;

     -- trailing tag
     tlob := tlob || '</kg>';

     -- text is returned in tlob parameter
end; 
/
list
show errors

-- Split a string into K-grams
-- the string MUST be cleaned first - all non-alphanums removed and all whitespace condensed

create or replace function kg_split_string( str varchar2, K integer ) return varchar2 as
  p       integer := 1;
  q       integer;
  endword integer;
  done    integer := 0;
  spc     varchar2(1) := ''; 
  work    varchar2(32767) := '';
begin

  done := 0;

  -- loop over the whole string

   while( p < length(str) and done != 1 ) loop

    -- find the next space 
    endword := instr( str, ' ', p);
    if endword <=p then 
       endword := length(str)+1;
    end if;

    -- loop over the current word

    while( (p + K) <= endword AND (p + K) <= length(str)+1 ) loop
      if endword <= p then
        done := 1; 
      else
        if endword - p > (K-1) then
          q := p + (K-1);
        else
          q := endword;
        end if;

        work := work || spc || substr( str, p, (q-p)+1);
        spc := ' ';

        p := p+1;
      end if;

    end loop;
    p := p+K;
    
  end loop;

  return work;

end;
/
-- list 
show errors

-- Helper function for queries:
-- Given a string, return the K-gram search version of that string if double-truncated
-- so if the string is 'froggy' we would return 'fro rog ogg ggy within kg'

create or replace function get_kgrams (str varchar2) return varchar2 is

  KGRAM_FIELD varchar2(30) := 'kg';

  K number := &K_LENGTH.;

  work        varchar2(4000) := '';

begin

     work := str;

     -- replace all non-alphanumeric strings (EXCEPT parens, wild cards) with a single space
     work := regexp_replace(work, '[^A-Za-z0-0\%\(\)]+', ' ');

     -- remove leading and trailing spaces
     work := regexp_replace(work, '^ ', ' ');
     work := regexp_replace(work, ' $', ' ');

     work := kg_split_string(work, K);

     work := work || ' within ' || KGRAM_FIELD;

     return work;

end;
/
list
show errors

exec ctx_ddl.drop_preference('my_datastore')
exec ctx_ddl.drop_section_group('my_sections')

exec ctx_ddl.create_preference('my_datastore', 'user_datastore')
exec ctx_ddl.set_attribute('my_datastore', 'procedure', 'kgram_userds')

exec ctx_ddl.create_section_group('my_sections', 'basic_section_group')
exec ctx_ddl.add_field_section('my_sections', 'kg', 'kg')

-- create an index using the user_datastore

create index tti on testtable(text) indextype is ctxsys.context
parameters ('datastore my_datastore section group my_sections');

--select * from ctx_user_index_errors;
--select token_text, token_type from dr$tti$i;

-- test it

prompt Simple search for "winston"
select text from testtable where contains( text, 'winston' ) > 0;

prompt Double-truncation search for "%pole%"
select text from testtable where contains( text, get_kgrams('pole') ) > 0;

prompt Double-truncation search for "%pole%" with conventional term
select text from testtable where contains( text, get_kgrams('pole')||' and bonaparte' ) > 0;


