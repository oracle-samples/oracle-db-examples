drop table mytext;
create table mytext( text clob );

insert into mytext values ('b<span style="background-color: rgb(189, 189, 252);">ecause it works</span><br><span style="font-weight: bold;">ad<span style="background-color:rgb(255, 255, 0);">ie</span>u</span>');

commit;

create or replace procedure my_proc 
     (rid in rowid, tlob in out nocopy clob) is 
     inStr     varchar2(32767);
     outStr    varchar2(32767);
     ch        varchar2(1);
     theSize   number;
     inTag     number := 0;
begin 
     -- this "for loop" will only execute once but it's easier this way than declaring a 
     -- separate cursor
     for c in ( select text from mytext where rowid = rid ) loop
        theSize := 32767;
        dbms_lob.read( c.text, theSize, 1, inStr );
        for p in 1 .. theSize loop
           ch := substr(inStr, p, 1);
           if ch = '<' then 
              inTag := 1;
           else 
              if ch = '>' then
                 inTag := 0;
              else 
                 if inTag = 0 then
                    outStr := outStr || ch;
                 end if;
              end if;
           end if;
        end loop;
     end loop;
     tlob := outStr;
end; 
/
show errors
list

exec ctx_ddl.drop_preference('my_datastore')

exec ctx_ddl.create_preference('my_datastore', 'user_datastore')
exec ctx_ddl.set_attribute('my_datastore', 'procedure', 'my_proc')

create index mytextindex on mytext (text)
indextype is ctxsys.context
parameters('datastore my_datastore filter ctxsys.null_filter stoplist ctxsys.empty_stoplist');

-- check for errors during indexing
select * from ctx_user_index_errors;

-- test
select * from mytext where contains (text, 'because') > 0;

