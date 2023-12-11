drop table te_isrd_nm;
create table te_isrd_nm (ISRD_NM varchar2(30));

insert into te_isrd_nm values ('CHINNA CORPORATION HK');
insert into te_isrd_nm values ('CHINA CORPORATION');
insert into te_isrd_nm values ('CHINA HK');
insert into te_isrd_nm values ('CORP CHINA');
insert into te_isrd_nm values ('CHINA HOME CORPORATION');
insert into te_isrd_nm values ('CHINE CORPORATION');
insert into te_isrd_nm values ('CHINA NEW HOME LTD');
insert into te_isrd_nm values ('CHINNE CORP.');
insert into te_isrd_nm values ('CANADA CORP.');

CREATE INDEX isrd_nm_ndx ON te_isrd_nm(isrd_nm) INDEXTYPE IS CTXSYS.CONTEXT;

select * from te_isrd_nm where contains (isrd_nm, 'fuzzy(china)') > 0;
select * from te_isrd_nm where contains (isrd_nm, 'fuzzy(china) corp%') > 0;
