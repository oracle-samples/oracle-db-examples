drop table ctx_themes;

create table CTX_THEMES (query_id number, 
                         theme varchar2(2000), 
                         weight number);

select text from tab1 where id = 1;
exec ctx_doc.themes('TAB1_IDX', 1, 'ctx_themes', 0, TRUE )
select theme from ctx_themes;

select text from tab1 where id = 2;
truncate table ctx_themes;
exec ctx_doc.themes('TAB1_IDX', 2, 'ctx_themes', 0, TRUE )
select theme from ctx_themes;

select text from tab1 where id = 3;
truncate table ctx_themes;
exec ctx_doc.themes('TAB1_IDX', 3, 'ctx_themes', 0, TRUE )
select theme from ctx_themes;

select text from tab1 where id = 4;
truncate table ctx_themes;
exec ctx_doc.themes('TAB1_IDX', 4, 'ctx_themes', 0, TRUE )
select theme from ctx_themes;

select text from tab1 where id = 5;
truncate table ctx_themes;
exec ctx_doc.themes('TAB1_IDX', 5, 'ctx_themes', 0, TRUE )
select theme from ctx_themes;
