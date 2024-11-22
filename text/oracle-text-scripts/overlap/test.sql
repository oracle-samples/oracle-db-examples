drop table dr$myindex$i;
create table dr$myindex$i (
 status                                     varchar2(4),
 TOKEN_TEXT				    VARCHAR2(64),
 TOKEN_TYPE				    NUMBER(10),
 TOKEN_FIRST				    NUMBER(10),
 TOKEN_LAST				    NUMBER(10),
 TOKEN_COUNT				    NUMBER(10),
 TOKEN_INFO                                 BLOB );


insert into dr$myindex$i values ( 'bood', 'hello', '0', 20, 30, 1, null );
insert into dr$myindex$i values ( 'good', 'hello', '0', 40, 50, 1, null );
insert into dr$myindex$i values ( 'bad ', 'hello', '0', 41, 42, 1, null );
insert into dr$myindex$i values ( 'bad ', 'hello', '0', 41, 54, 1, null );
insert into dr$myindex$i values ( 'bad ', 'hello', '0', 70, 80, 1, null );
insert into dr$myindex$i values ( 'good', 'hello', '0', 68, 72, 1, null );
insert into dr$myindex$i values ( 'good', 'hello', '1', 22, 28, 1, null );
insert into dr$myindex$i values ( 'bad ', 'hello', '1', 22, 29, 1, null );
insert into dr$myindex$i values ( 'bad ', 'hello', '1', 22, 31, 1, null );
insert into dr$myindex$i values ( 'bad ', 'hello', '1', 30, 31, 1, null );
insert into dr$myindex$i values ( 'good', 'hello', '1', 32, 33, 1, null );
insert into dr$myindex$i values ( 'good', 'hello', '1', 50, 60, 1, null );
insert into dr$myindex$i values ( 'bad ', 'hello', '1', 51, 60, 1, null );

insert into dr$myindex$i values ( 'good', 'fooba', '1',  1, 10, 1, null );
insert into dr$myindex$i values ( 'bad ', 'fooba', '1',  2, 20, 1, null );
insert into dr$myindex$i values ( 'ques', 'fooba', '1', 12, 18, 1, null );

