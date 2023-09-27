drop table facility;

create table facility (
  facility_id number, 
  name        varchar2(2000)
);

insert into facility values (1, 'Furman University');

create index facind on facility(name) indextype is ctxsys.context;

drop table test_match_weight;

create table test_match_weight (
  group_id    number, 
  param_name  varchar2(200), 
  weight      number
);

insert into test_match_weight values (1,'NAME', 0.5);

set serveroutput on size 1000000

declare
  CURSOR fac_fullname_cur(p_facilityName VARCHAR2) IS  
    SELECT DISTINCT f.facility_id AS facid, f.name,
                    case when score(1)>75 then w.weight*8
                         when score(1)>50 then w.weight*6
                         when score(1)>25 then w.weight*4
                         else w.weight*2 end weightedScore, 
                    score(1) as scr
    FROM facility f
       , test_match_weight w
    WHERE contains(f.name, 
          '<query>
               <textquery>  '''''||p_facilityName||'''''
                 <progression>
                   <seq><rewrite>transform((TOKENS, "{", "}", " "))</rewrite></seq>
                   <seq><rewrite>transform((TOKENS, "?{", "}", " "))</rewrite></seq>
                   <seq><rewrite>transform((TOKENS, "{", "}", "OR"))</rewrite></seq>
                   <seq><rewrite>transform((TOKENS, "?{", "}", "OR"))</rewrite></seq>
                 </progression>
               </textquery>
            </query>', 1) > 0
      AND w.group_id = 1
      AND w.param_name = 'NAME'
      order by 3 desc;
  number_of_steps  integer := 4;
  score_range_size integer;      -- 33 for 3 steps, 25 for 4, 20 for 5 etc
  this_score_group integer;      -- final step is 1, penultimate step is 2 ...
  last_score_group integer := 0; -- to compare change
  var_FacName  VARCHAR2(2000);
begin
var_FacName := 'Furman University';
    for c in fac_fullname_cur(var_FacName) loop
        score_range_size := 100/number_of_steps;
        this_score_group := c.scr/score_range_size;

        exit when this_score_group < last_score_group;
        last_score_group := this_score_group;
        dbms_output.put_line(c.facid||', '||c.name||',  '||length(c.name)||',  '||c.scr);
    end loop; 
end;      
/
