-- ctxrule can be used to creating 'routing' indexes
-- here we imagine a news feed coming into a newspaper, and the various editors have saved
-- queries which identify stories of interest to their specialist field.

-- The MATCHES search provides the story (or story headline/summary) as an argument, and the
-- editors interested in that story are flagged

set echo on

drop table searches
/
create table searches( search_terms varchar2(2000), search_area varchar2(30), owner_name varchar2(30) )
/

insert into searches values( 'barack obama', 'US Politics', 'John' )
/
insert into searches values( 'washington', 'US Politics', 'John' )
/
insert into searches values( 'iraq or iran', 'Middle East', 'Peter' )
/
insert into searches values( 'finance or financial' , 'Economics', 'Mike' )
/
insert into searches values( 'NEAR( (financial, US) )', 'US Economics', 'Mike' )
/

create index search_index on searches( search_terms ) indextype is ctxsys.ctxrule
/

select search_area, owner_name 
from searches 
where matches(search_terms, 'Barack Obama yesterday announced that he is flying to Iraq to discuss the financial status of US interests' ) > 0
and owner_name = 'Mike'
/

select search_area, owner_name 
from searches 
where matches(search_terms, 'Yesterday in Washington nothing of interest happened.' ) > 0
/

