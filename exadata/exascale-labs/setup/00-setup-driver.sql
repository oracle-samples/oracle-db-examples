-- Run the interactive SALES_MAIN creation script and propagate SQL failures.

@00-create-sales-main.sql
EXIT SQL.SQLCODE
