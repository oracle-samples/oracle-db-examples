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
select base.id, substr(text,1,60) from 
  postings t1
 ,postings t2
 ,postings t3
 ,base
  where 
      base.id = t1.id
  and t1.id = t2.id
  and t1.gram like 'ani'
  and t2.pos = t1.pos + 3
  and t2.id = t3.id
  and t3.gram like 's%' 
  and t2.gram like 'mal'
  and t3.pos = t2.pos + 3;
 
