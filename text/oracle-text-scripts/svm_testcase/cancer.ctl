LOAD DATA 
INFILE 'cancer_specific_abstracts.csv'
replace
   INTO TABLE cancer
   FIELDS TERMINATED BY ',' optionally enclosed by '"' 
   (abstract  char(32000))
