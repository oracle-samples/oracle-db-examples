set tab off
var val number

exec :val := -1
prompt val=-1
select /* SPM */ count(*),sum(val) from mysales where sale_type = :val;
@plan

exec :val := 1
prompt val=1
select /* SPM */ count(*),sum(val) from mysales where sale_type = :val;
@plan
