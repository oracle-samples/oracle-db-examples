LOAD DATA 
INFILE 'maternal_specific_abstracts.csv'
replace
   INTO TABLE maternal
   FIELDS TERMINATED BY ',' optionally enclosed by '"' 
   (abstract  char(32000))
