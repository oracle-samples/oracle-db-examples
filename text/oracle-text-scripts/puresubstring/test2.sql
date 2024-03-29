with postings as (
select gram, id, pos from base$text$grams g
  nested data columns (
    gram,
    nested posting[*] columns (
      id,
      nested pos[*] columns (pos path '$')
    )
  )
)
select distinct base.id as id, substr(base.text,1, 60) as text 
from base base, postings t1
 where base.id = t1.id and 
 t1.gram like 'dog';
