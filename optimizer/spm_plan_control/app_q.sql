var idv number
exec :idv := 5

select sum(num) from sales where id < :idv;

@plan
