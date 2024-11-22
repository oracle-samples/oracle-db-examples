connect / as sysdba

drop user demo cascade;

create user demo identified by demo default tablespace users temporary tablespace temp quota unlimited on users;

grant connect,resource to demo;

connect demo/demo

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

-- drop table testtable;
create table testtable (id number primary key, text varchar2(2000));

-- drop table k_index_tab;
create table k_index_tab (id number, kgram varchar2(3));

insert into testtable values (1, 'vic moore');
insert into testtable values (2, 'roger ford');
insert into testtable values (3, 'winston church churchill');
insert into testtable values (4, 'napoleon p. bonaparte');
insert into testtable values (5, 'peter the pole');
insert into testtable values (6, 'spolek polinski');--

-- K-Gram processor
-- transforms "the quick brown fox jumps over the lazy dog" into
-- "the quick brown fox jumps over the lazy dog <kg>the qui uic ick bro row own fox jum ump mps ove ver the laz azy dog</kg>"

-- EXPECTATIONS

-- the text to be indexed is in the text column (VARCHAR2) of a table called testtable

-- LIMITATION

1-- the maximum length of the encoded output string is 32K-1

-- Split a string into K-grams
-- the string MUST be cleaned first - all non-alphanums removed and all whitespace condensed

create or replace procedure kg_split_string( id number, str varchar2, K integer ) as
  p       integer := 1;
  q	  integer;     
  endword integer;
  done    integer := 0;
  -- spc     varchar2(1) := ''; 
  work    varchar2(32767) := '';
begin

  done := 0;

  -- loop over the whole string
  while( p < length(str) and done != 1 ) loop

      q := p + K-1;
      if p + K > length(str) then
        q := length(str);
      end if;
      insert into k_index_tab values (id, substr( str, p, (q-p)+1) );
      p := p+1;

  end loop;

end;
/
list 
show errors

create or replace procedure kgram_processor
     is 
     v_text varchar2(4000);
     work   varchar2(32767); 
     v_id   number;   
     K      number := &K_LENGTH;


begin 

     for c in ( select id, text from testtable ) loop

          v_text := c.text;
          v_id   := c.id;
          -- add the untransformed text first
     
          work := v_text;
     
          -- replace all non-alphanumeric strings with a single space
          -- work := regexp_replace(work, '[^A-Za-z0-0]+', ' ');
     
          -- remove leading and trailing spaces
          work := regexp_replace(work, '^ ', ' ');
          work := regexp_replace(work, ' $', ' ');
     
          kg_split_string(v_id, work, K);
     
     end loop;

end; 
/

list
show errors

exec kgram_processor

select * from k_index_tab;

column text format a40

select * from 
   testtable t
  ,k_index_tab k1
  ,k_index_tab k2
  ,k_index_tab k3
  ,k_index_tab k4    
where 
       k1.id = k2.id 
   and k2.id = k3.id 
   and k3.id = k4.id    
   and k4.id = t.id
   and k1.kgram = 'chu' 
   and k2.kgram = 'hur'
   and k3.kgram = 'urc'
   and k4.kgram = 'rch'
/
