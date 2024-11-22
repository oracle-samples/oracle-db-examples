LOAD DATA 
INFILE 'microbes_specific_abstracts.csv'
replace
   INTO TABLE microbes
   FIELDS TERMINATED BY ',' optionally enclosed by '"' 
   (abstract  char(32000))
