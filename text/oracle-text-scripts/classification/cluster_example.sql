-- Clustering example from the docs, adapted to use a user_datastore to decide which rows to process

/* collect document into a table */
drop table collection;

create table collection (id number primary key, text varchar2(4000), use_this_row number);
insert into collection values (1, 'Oracle Text can index any document or textual content.', 1);
insert into collection values (2, 'Ultra Search uses a crawler to access documents.', 0);
insert into collection values (3, 'XML is a tag-based markup language.', 1);
insert into collection values (4, 'Oracle Database 11g XML DB treats XML as a native datatype in the database.', 1);
insert into collection values (5, 'There are three Text index types to cover all text search needs.', 0);
insert into collection values (6, 'Ultra Search also provides API for content management solutions.', 1);

create or replace procedure my_proc 
     (rid in rowid, tlob in out nocopy clob) is 
begin 
     -- this "for loop" will only execute once but it's easier this way than declaring a 
     -- separate cursor
     for c in ( select text, use_this_row from collection
                where rowid = rid ) loop
          if c.use_this_row = 1 then
                tlob := c.text;
          else
                tlob := '';
          end if;
     end loop;
end; 
/
list
show errors

exec ctx_ddl.drop_preference('my_datastore')

exec ctx_ddl.create_preference('my_datastore', 'user_datastore')
exec ctx_ddl.set_attribute('my_datastore', 'procedure', 'my_proc')

create index collectionx on collection(text) 
   indextype is ctxsys.context parameters('datastore my_datastore nopopulate');

drop table restab;

/* prepare result tables, if you omit this step, procedure will create table automatically */
create table restab (       
       docid NUMBER,
       clusterid NUMBER,
       score NUMBER);

drop table clusters;

create table clusters (
       clusterid NUMBER,
       descript varchar2(4000),
       label varchar2(200),
       sze   number,
       quality_score number,
       parent number);

/* set the preference */
exec ctx_ddl.drop_preference('my_cluster');
exec ctx_ddl.create_preference('my_cluster','KMEAN_CLUSTERING');
exec ctx_ddl.set_attribute('my_cluster','CLUSTER_NUM','3');

/* do the clustering */
exec ctx_output.start_log('my_log');
exec ctx_cls.clustering('collectionx','id','restab','clusters','my_cluster');
exec ctx_output.end_log;

select docid, clusterid, score from restab order by clusterid, docid;
