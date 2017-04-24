select /* SPMTEST */ /*+ INDEX(sales salesi) */ * from sales WHERE sale_date >= trunc(sysdate);

@plan
