connect roger/roger

create or replace type t1_rec_typ as table of number;
/

 create or replace function counter(start_no number, offset number)
   return t1_rec_typ
   pipelined
 is
 begin
   for i in start_no..start_no+offset-1 loop
     pipe row(i);
   end loop;
   return;
 end;
/

create tablespace TS_AR_2005 DATAFILE '/scratch/oradata/test/TS_AR_2005.DBF' SIZE 50M ;
create tablespace TS_2005 DATAFILE    '/scratch/oradata/test/TS_2005.DBF' SIZE 50M ;
create tablespace TS_2006 DATAFILE    '/scratch/oradata/test/TS_2006.DBF' SIZE 50M ;
create tablespace TS_2007 DATAFILE    '/scratch/oradata/test/TS_2007.DBF' SIZE 50M ;
alter tablespace TS_2007 add DATAFILE '/scratch/oradata/test/TS_2007_2.DBF' SIZE 50M ;

-- alter system set READ_ONLY_OPEN_DELAYED=true scope=spfile;

create table B (
 id number not null, trans varchar2(30) not null, c clob,
 mf_fk number(1), createdate date not null)
 partition by range (createdate)
 (
   partition year_2005 values
     less than(to_date('2006-01-01','YYYY-MM-DD')) tablespace TS_2005
     LOB (c) STORE AS ( tablespace TS_2005 ),
   partition q_2006_1 values
     less than(to_date('2006-04-01','YYYY-MM-DD')) tablespace TS_2006
     LOB (c) STORE AS ( tablespace TS_2006 ),
   partition q_2006_2 values
     less than(to_date('2006-07-01','YYYY-MM-DD')) tablespace TS_2006
     LOB (c) STORE AS ( tablespace TS_2006 ),
   partition q_2006_3 values
     less than(to_date('2006-10-01','YYYY-MM-DD')) tablespace TS_2006
     LOB (c) STORE AS ( tablespace TS_2006 ),
   partition q_2006_4 values
     less than(to_date('2007-01-01','YYYY-MM-DD')) tablespace TS_2006
     LOB (c) STORE AS ( tablespace TS_2006 ),
   partition rest values LESS THAN (MAXVALUE) tablespace TS_2007
     LOB (c) STORE AS ( tablespace TS_2007 ));

insert /*+APPEND */ into B (id, trans, c, mf_fk, createdate)
select t.column_value id,
      'record '||to_char(t.column_value) trans,
      'clob: '||to_char(t.column_value) c,
      mod(t.column_value,2) mf_fk,
      to_date('2005-01-01','YYYY-MM-DD')+mod(t.column_value,1000) createdate
from table(counter(1,100000) ) t;
commit;
-- 100000 rows

create unique index b_pk on b (id, createdate)   LOCAL
(PARTITION "YEAR_2005" TABLESPACE TS_2005 ,
 PARTITION "Q_2006_1" TABLESPACE TS_2006 ,
 PARTITION "Q_2006_2" TABLESPACE TS_2006 ,
 PARTITION "Q_2006_3" TABLESPACE TS_2006 ,
 PARTITION "Q_2006_4" TABLESPACE TS_2006 ,
 PARTITION "REST" TABLESPACE TS_2007 );

alter table b add constraint b_pk primary key (id, createdate);

-- create a local context domain index

exec ctx_ddl.drop_preference('STORE_2005');
exec ctx_ddl.create_preference('STORE_2005','basic_storage');
exec ctx_ddl.set_attribute ('STORE_2005','I_TABLE_CLAUSE', 'tablespace ts_2005');
exec ctx_ddl.set_attribute ('STORE_2005','K_TABLE_CLAUSE', 'tablespace ts_2005');
exec ctx_ddl.set_attribute ('STORE_2005','R_TABLE_CLAUSE', 'tablespace ts_2005');
exec ctx_ddl.set_attribute ('STORE_2005','N_TABLE_CLAUSE', 'tablespace ts_2005');
exec ctx_ddl.set_attribute ('STORE_2005','I_INDEX_CLAUSE', 'tablespace ts_2005');
exec ctx_ddl.set_attribute ('STORE_2005','P_TABLE_CLAUSE', 'tablespace ts_2005');

exec ctx_ddl.drop_preference('STORE_2006');
exec ctx_ddl.create_preference('STORE_2006','basic_storage');
exec ctx_ddl.set_attribute ('STORE_2006','I_TABLE_CLAUSE', 'tablespace ts_2006');
exec ctx_ddl.set_attribute ('STORE_2006','K_TABLE_CLAUSE', 'tablespace ts_2006');
exec ctx_ddl.set_attribute ('STORE_2006','R_TABLE_CLAUSE', 'tablespace ts_2006');
exec ctx_ddl.set_attribute ('STORE_2006','N_TABLE_CLAUSE', 'tablespace ts_2006');
exec ctx_ddl.set_attribute ('STORE_2006','I_INDEX_CLAUSE', 'tablespace ts_2006');
exec ctx_ddl.set_attribute ('STORE_2006','P_TABLE_CLAUSE', 'tablespace ts_2006');

exec ctx_ddl.drop_preference('STORE_2007');
exec ctx_ddl.create_preference('STORE_2007','basic_storage');
exec ctx_ddl.set_attribute ('STORE_2007','I_TABLE_CLAUSE', 'tablespace ts_2007');
exec ctx_ddl.set_attribute ('STORE_2007','K_TABLE_CLAUSE', 'tablespace ts_2007');
exec ctx_ddl.set_attribute ('STORE_2007','R_TABLE_CLAUSE', 'tablespace ts_2007');
exec ctx_ddl.set_attribute ('STORE_2007','N_TABLE_CLAUSE', 'tablespace ts_2007');
exec ctx_ddl.set_attribute ('STORE_2007','I_INDEX_CLAUSE', 'tablespace ts_2007');
exec ctx_ddl.set_attribute ('STORE_2007','P_TABLE_CLAUSE', 'tablespace ts_2007');

CREATE INDEX "TEXT_IDX" ON "B" ("C")
INDEXTYPE IS "CTXSYS"."CONTEXT" LOCAL (
PARTITION "YEAR_2005" PARAMETERS ('storage STORE_2005') ,
PARTITION "Q_2006_1" PARAMETERS ('storage STORE_2006') ,
PARTITION "Q_2006_2" PARAMETERS ('storage STORE_2006') ,
PARTITION "Q_2006_3" PARAMETERS ('storage STORE_2006') ,
PARTITION "Q_2006_4" PARAMETERS ('storage STORE_2006') ,
PARTITION "REST" PARAMETERS ('storage STORE_2007') );

-- no global indexes!

-------------- -- Method 1:

This mechanism is considered too slow as the indexes would be unusable for a longer period

alter table b merge partition YEAR_2005 tablespace TS_AR_2005;

ALTER TABLE b MERGE PARTITIONS
 q_2006_1, q_2006_2 INTO PARTITION q_2006_2 tablespace TS_AR_2005;
ALTER TABLE b MERGE PARTITIONS
 q_2006_2, q_2006_3 INTO PARTITION q_2006_3 tablespace TS_AR_2005;
ALTER TABLE b MERGE PARTITIONS
 q_2006_3, q_2006_4 INTO PARTITION q_2006_4 tablespace TS_AR_2005 update indexes;

alter table b rename partition q_2006_4 to year_2006;

-- somehow the relevant partition name in the index is q_2006_3 ???

-- move the domain index to the right tablespace

-- Method 2:

create table b_move compress
LOB (c) STORE AS ( tablespace TS_2005 ) tablespace TS_AR_2005 as
select * from b partition (Q_2006_1)
order by trans;
-- Forløbet: 00:00:00.61
insert /*+APPEND */ into b_move
select * from b partition (Q_2006_2)
order by trans;
commit;
insert /*+APPEND */ into b_move
select * from b partition (Q_2006_3)
order by trans;
commit;
insert /*+APPEND */ into b_move
select * from b partition (Q_2006_4)
order by trans;
commit;

create unique index b_move_pk on b_move (id, createdate)
TABLESPACE TS_AR_2005;

alter table b_move add constraint b_move_pk primary key (id, createdate)
using index;

-- exec ctx_ddl.drop_preference('STORE_AR_2005');
exec ctx_ddl.create_preference('STORE_AR_2005','basic_storage');
exec ctx_ddl.set_attribute ('STORE_AR_2005','I_TABLE_CLAUSE', 'tablespace ts_ar_2005');
exec ctx_ddl.set_attribute ('STORE_AR_2005','K_TABLE_CLAUSE', 'tablespace ts_ar_2005');
exec ctx_ddl.set_attribute ('STORE_AR_2005','R_TABLE_CLAUSE', 'tablespace ts_ar_2005');
exec ctx_ddl.set_attribute ('STORE_AR_2005','N_TABLE_CLAUSE', 'tablespace ts_ar_2005');
exec ctx_ddl.set_attribute ('STORE_AR_2005','I_INDEX_CLAUSE', 'tablespace ts_ar_2005');
exec ctx_ddl.set_attribute ('STORE_AR_2005','P_TABLE_CLAUSE', 'tablespace ts_ar_2005');


CREATE INDEX TEXT_IDX_move ON b_move (c)
INDEXTYPE IS "CTXSYS"."CONTEXT" PARAMETERS ('storage STORE_AR_2005');

-- from this point we need to change production structures

alter table b drop partition q_2006_1;
alter table b drop partition q_2006_2;
alter table b drop partition q_2006_3;

alter table b exchange partition q_2006_4 with table b_move
including indexes with validation;

alter table b rename partition q_2006_4 to year_2006;

-- from a different session the following PL/SQL block has been executed:

create table lock_save (
 no number,
 type varchar2(2),
 id1 number,
 id2 number,
 lmode number,
 request number,
 ctime number,
 block number,
 note varchar2(30));

truncate table lock_save;

select * from v$mystat;

declare
 i number;
 l_note varchar2(30);
 l_cnt number;
begin
 i := 1;
 loop
   select a.status||' - '||b.status into l_note
   from user_ind_partitions a, user_ind_partitions b
   where a.index_name ='B_PK'
   and b.index_name ='TEXT_IDX'
   and a.partition_name = 'YEAR_2005'
   and b.partition_name = 'YEAR_2005';
   select count(*) into l_cnt from b
   where createdate between to_date('2006-01-01','YYYY-MM-DD')
     and to_date('2006-12-31','YYYY-MM-DD');
   l_note := l_note||' '||to_char(l_cnt);
   insert into lock_save (no, type, id1, id2, lmode, request, ctime, block, note)
   select i, type, id1, id2, lmode, request, ctime, block, l_note
   from v$lock
   where lmode in (3, 5, 6)
   and sid= 83;
   commit;
   i:=i+1;
   exit when i > 10000;
 end loop;
end;
  column note format a22
select type, id1, id2, lmode, request, note, count(*)
from lock_save
group by type, id1, id2, lmode, request, note
order by type, id1, id2, lmode, request, note;
