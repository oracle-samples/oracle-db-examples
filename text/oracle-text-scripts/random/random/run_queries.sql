set timing on

-- Single partition: partition elimination by id < 250000
select /*+ first_rows(10) */ score, id from
( select /*+ DOMAIN_INDEX_SORT */ score(1) as score, id 
  from mydocs
  where contains (text, 'bo and ba', 1) > 0
  and id < 250000
  order by score(1) desc )
where rownum <= 10
/

-- repeat for cached result
/

-- Two partitions
select /*+ first_rows(10) */ score, id from
( select score(1) as score, id 
  from mydocs
  where contains (text, 'bo and ba', 1) > 0
  and id < 500000
  order by score(1) desc )
where rownum <= 10
/

-- repeat for cached result
/

