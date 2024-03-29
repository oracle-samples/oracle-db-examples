connect roger/roger

drop table storv;

create table storv (
  id number(3),          
  jdata varchar2(4000) ) partition by range(id)(
partition p1 values less than (10),                       
partition p2 values less than (20),                       
partition p3 values less than (30),                       
partition p4 values less than (maxvalue)) ;               


 insert into storv(id,jdata) values(10,
'{   "ID":1, "firstname":"John", DOB:"01-01-1980", "age":33, "hobbies":[ "reading","cinema",{ "sports":["volley-ball","snowboard"] } , [1,2,3] ], "address":{ }                                           
}' ) ;                                                                                               
insert into storv(id,jdata) values(20,                                                               
'{   "ID":20, "name":"Osama", "firstname":"Bin Laden", DOB:"01-01-1980", "age":16, "hobbies":[ "killing","bombing",{ "sports":["AK47","planes"] } , [1,2,3], 500 ], "address":{place:"hell"}              
}' ) ;   


create index dxbook on storv(jdata) indextype is ctxsys.context local;
select * from storv where contains(jdata, 'john')>0;

conn ctxsys/ctxsys
col idx_name format a10
col idx_status format a10
select idx_name, idx_status, idx_type from dr$index where idx_name = 'DXBOOK';

exec CTX_ADM.MARK_FAILED('roger','dxbook');

connect roger/roger

select * from storv where contains(jdata, 'john')>0;
