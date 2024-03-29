-- Script to delete overlapping ranges in the $I table

-- change the define line below to include your actual index name

-- this only works with non LOCAL (i.e. non partitioned) indexes
-- for local indexes it will need to be changed slightly and run on each partition
-- separately

define INDEX_NAME=test

-- uncomment this to create the test table with overlaps
-- @test

column token_text format a10
column token_type format 999

set timing on

delete from dr$&INDEX_NAME$i where rowid in (
 select b.rowid
    from
    dr$&INDEX_NAME$i a, dr$&INDEX_NAME$i b
    where a.token_type = b.token_type
      and  a.token_text = b.token_text
      and ( NOT ( a.token_first = b.token_first 
                  AND a.token_last  = b.token_last ) )
      and a.token_first <= b.token_first and a.token_last >= b.token_first
      and ( not (a.token_first = b.token_first and b.token_last < a.token_last ) )
)
/

commit;

-- select status, token_type, token_text, token_first, token_last from dr$myindex$i;
