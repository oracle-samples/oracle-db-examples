REM  Create a table basic_lob_table
REM
connect testuser/<your_db_password>;
drop table basic_lob_table;
create table basic_lob_table (x varchar2 (30), b blob, c clob);
