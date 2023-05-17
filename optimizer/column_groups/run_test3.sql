--
-- This test scans the test tables and looks for column correlation
-- There is no need to run test queries
--
alter session set OPTIMIZER_USE_PENDING_STATISTICS = FALSE;
@@t0
@@t1
@@t2_2
@@load_sqlset MY_EXAMPLE_SQLSET
@@cg_from_sts.sql MY_EXAMPLE_SQLSET y
@@t6

exec dbms_sqltune.drop_sqlset('MY_EXAMPLE_SQLSET',user);
