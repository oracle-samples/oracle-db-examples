REM  replace scott/tiger with you database username/password
REM
connect scott/tiger;
drop table basic_lob_table;
create table basic_lob_table (x varchar2 (30), b blob, c clob);
