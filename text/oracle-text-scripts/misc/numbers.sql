drop table t;

create table t (x varchar2(200));

insert into t values ('1
1.2
3.4.5
6,.78
876.5,432
a3
3a
8t.3.2
8t.t3.2
7q.r.7s
6w.5x.4y
b4.5
33,,44
c6.7.8
123,456
234,4567
345,6,7,8
678,901.234.567
x.9
y.56
z1.78
p7,890
7,401k
q8,901.2
');

exec ctx_ddl.drop_stoplist('mystop')
exec ctx_ddl.create_stoplist('mystop', 'basic_stoplist')
exec ctx_ddl.add_stopclass('mystop', 'numbers')

create index ti on t(x) indextype is ctxsys.context 
--parameters ('stoplist mystop')  -- find out which are pure numbers by uncommenting
/

select token_text from dr$ti$i;
