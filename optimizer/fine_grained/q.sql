alter system flush shared_pool;

select /* TESTFG */ count(*) from t1 where id = 1;
@plan
select /* TESTFG */ count(*) from t1 where val1 = 1;
@plan
select /* TESTFG */ count(*) from t2 where id = 1;
@plan
select /* TESTFG */ count(*) from t2 where id = 1+150000;
@plan
select /* TESTFG */ count(*) from t2 where val1 = 1;
@plan
select /* TESTFG */ /*+ INDEX_FFS(t new1) */ sum(val2) from t1 t;
@plan
select /* TESTFG */ count(*) from t2 where id < (select max(id) from t1);
@plan
select /* TESTFG */ /*+ USE_INVISIBLE_INDEXES */ count(*) from t1 where val2<50;
@plan
select /* TESTFG */ count(*) from t2 partition (p2);
@plan
select /* TESTFG */ count(*) from t2 partition (p1);
@plan
update /* TESTFG */ t1 set val1 = val1 + 1 where val1 < 50;
update /* TESTFG */ t2 set val1 = val1 + 1 where val1 < 50;
update /* TESTFG */ t1 set val1 = val1 + 1 where id < 50;
update /* TESTFG */ t2 set val1 = val1 + 1 where id < 50;
commit;
