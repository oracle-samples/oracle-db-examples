select cat_id from rules
       where matches (rule, :lob) > 0
/
