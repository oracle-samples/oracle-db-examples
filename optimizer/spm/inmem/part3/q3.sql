set tab off
var val number

select /* SPM */ count(*),sum(val) from mysales where sale_type in (2,3);
@plan
