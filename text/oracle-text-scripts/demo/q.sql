select * from docs 
where contains (filename, '
table and 
( 
  (author within meta@name) 
   and 
  (ford within meta@content) 
)
') > 0;
