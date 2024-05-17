select * from docs 
where contains (filename, '
configuration manager and 
( 
  (author within meta@name) 
   and 
  (Oracle within meta@content) 
)
') > 0;
