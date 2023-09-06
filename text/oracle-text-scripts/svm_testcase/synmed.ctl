LOAD DATA 
INFILE 'synmed_specific_abstracts.csv'
replace
   INTO TABLE synmed
   FIELDS TERMINATED BY ',' optionally enclosed by '"' 
   (abstract  char(32000))
