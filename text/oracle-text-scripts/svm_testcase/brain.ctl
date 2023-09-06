LOAD DATA 
INFILE 'brain_specific_abstracts.csv'
replace
   INTO TABLE brain
   FIELDS TERMINATED BY ',' optionally enclosed by '"' 
   (abstract  char(32000))
