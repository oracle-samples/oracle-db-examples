col CAT_NAME for a15
set pages 9999 trimspool on lines 200
spool match_scores.txt

drop table test.brain_abstracts_with_pk;
drop table test.brain_match_scores;
drop table test.match_scores;


create table test.brain_abstracts_with_pk ( docid number primary key, abstract CLOB ); 
insert into test.brain_abstracts_with_pk (select test.abstract_seq.nextval, abstract from test.brain);
commit;


create table test.brain_match_scores as (
select distinct d.docid, cat_name, match_score(1) match_score
from test.restab r, test.testcategory t, test.brain_abstracts_with_pk d
where matches(rule, d.abstract ,1)>0
  and r.cat_id = t.cat_id
)
;

-- these should all be "brain" categories, since I am selecting ONLY "brain" abstracts
select docid, cat_name, match_score from test.brain_match_scores m1 where match_score = (select max(match_score) from test.brain_match_scores m2 where m1.docid = m2.docid)
order by 1,2;

spool off

exit

