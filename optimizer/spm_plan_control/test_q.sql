var idv number
exec :idv := 5

select /*+ FULL(sales) */ sum(num) from sales where id < :idv;

@plan
