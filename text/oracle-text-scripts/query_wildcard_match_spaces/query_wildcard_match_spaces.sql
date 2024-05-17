-- demo script showing how we can make wildcards match spaces
-- in this case, the customer wanted to index short strings and use '*' as their wildcard
-- a wildcard needed to match spaces as well as alphanumerics, which it normally doesn't

-- so the query parser converts the query to turn 'do*g' into 'do% AND %g'
-- a single word such as 'dodging' will match both sides of the AND
-- a phrase such as 'the dome has no fog' will match because 'do%' matches 'dome' and '%g' matches 'fog'
-- it's not foolproof 'do*g' will also match 'the fog in the dome' since AND is not order dependant
-- alternatively could use NEAR with the ORDER requirement, but that would be rather more complex

drop table t;
create table t (c varchar2(2000));

insert into t values ('applicat ml');
insert into t values ('applicatml');
insert into t values ('applicatml');
insert into t values ('applicationxml');
insert into t values ('application/xml');
insert into t values ('application with blah blah blah in between xml');

create index tc on t(c) indextype is ctxsys.context;

set serverout on
set echo on

create or replace function parse_search (
   input_string varchar2,
   multi_wildcard varchar2 default '*'
   ) return varchar2 is
  buff varchar2(2000);
begin
  buff := input_string;
  -- replace anything that's not a wildcard or alphanumeric with a space
  buff := regexp_replace (buff, '[^[:alnum:]\' || multi_wildcard || ']', ' ');
  -- replace wildcards surrounded by alphanumerics with "% %"
  buff := regexp_replace (buff, '([[:alnum:]])\' || multi_wildcard || '([[:alnum:]])', '\1% %\2');
  -- replace remaining wildcards with "%"
  buff := replace (buff, multi_wildcard, '%');
  -- replace any strings of spaces with " AND "
  buff := regexp_replace (buff, '[[:space:]]+', ' AND ');
  dbms_output.put_line('Search expression was: '|| buff);
  return buff;
end;
/
show errors

select * from t where contains (c, parse_search('applicat*ml')) > 0;
select * from t where contains (c, parse_search('applicat*ml')) > 0;
select * from t where contains (c, parse_search('application/*ml')) > 0;
