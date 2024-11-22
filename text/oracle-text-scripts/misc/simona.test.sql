set serveroutput on size unlimited;

set trimspool on
set linesize 999

spool output.log

drop table roger_duplicate;
create table roger_duplicate 
  (page number, id varchar2(100));

declare
  mPage          number(9);
  mMainDetail    number(9);
  mRS            varchar2(4000);
  mStart_Hit_Num number(9);
  mEnd_Hit_Num   number(9);  
  mCount         number(9);
  mHasDuplicates number(9);
  page_number    number := 0;
  plaintext      varchar2(32000);

begin
  -- Test this script on 2 ranges:
  -- start_hit_num -> end_hit_num
  -- 11 -> 20
  -- 21 -> 30
  -- gives duplicates in the resultset
  mPage       := 20;
  dbms_output.put_line('page size = ' || mPage); 
  mMainDetail := 6000;
  dbms_output.put_line('start id = ' || mMainDetail); 
  
  loop
    execute immediate('truncate table ROGER_DUPLICATE');
    dbms_output.put_line('ROGER_DUPLICATE truncated'); 

    mStart_Hit_Num := 1;
    mEnd_Hit_Num   := mPage;
  
    dbms_output.put_line('iteration started...'); 
    loop
      page_number := page_number + 1;
      ctx_query.result_set (index_name => 'TEST_RVH_IDX',
                            result_set => mRS,
                            query      => '00' || mMainDetail || '% INPATH(//MediaAsset/@segmentId)',
                             result_set_descriptor =>  '
       <ctx_result_set_descriptor>  
        <count/>
        <hitlist start_hit_num="' || mStart_Hit_Num || '" end_hit_num="' || mEnd_Hit_Num || '" order="eventdate desc, logid">
          <score/>
          <rowid/>
          <sdata name="logid"/>
          <sdata name="eventdate"/>
        </hitlist>
      </ctx_result_set_descriptor>');

      dbms_output.put_line(' query done: Page ' || page_number ||' start_hit_num="' || mStart_Hit_Num || '" end_hit_num="' || mEnd_Hit_Num || '"'); 
      
      dbms_output.put_line(mRS);

      insert into ROGER_DUPLICATE
        (page, id)
      (select page_number, a_rowid
       from XMLTable('/ctx_result_set/hitlist/hit'
         passing xmltype(mRS)
         columns
           a_rowid rowid path 'rowid/text()'
         ));
      dbms_output.put_line('  inserted ' || sql%rowcount || ' record(s) into ROGER_DUPLICATE'); 

      select extractvalue(xmltype(mRS),'/ctx_result_set/count/text()') into mCount
      from Dual;
      dbms_output.put_line('  extracted count = ' || mCount); 
      
      select count(*)
        into mHasDuplicates
      from dual
      where exists (select 1
                    from ROGER_DUPLICATE t
                    group by t.id
                    having count(*) > 1);

      if (mHasDuplicates = 1) then
        dbms_output.put_line(' DUPLICATES ENCOUNTERED!!!');     
        dbms_output.put_line('  - mMainDetail    = ' || mMainDetail || ' (= "00' || mMainDetail || '")');
        dbms_output.put_line('  - mStart_Hit_Num = ' || mStart_Hit_Num);
        dbms_output.put_line('  - mEnd_Hit_Num   = ' || mEnd_Hit_Num);
        exit;
      end if;
      
      mStart_Hit_Num := mEnd_Hit_Num + 1;
      mEnd_Hit_Num := mEnd_Hit_Num + mPage;
       
      exit when mStart_Hit_Num > mCount;
    end loop;
    
    dbms_output.put_line('HasDuplicates => ' || mHasDuplicates); 
    if mHasDuplicates = 1 then
      commit;
      dbms_output.put_line('-> commit done');
      
      dbms_output.put_line('DUPLICATED ROW ID''s');
      dbms_output.put_line('====================');
      -- return the result
      for r_roger_duplicate in
        (select t.id , count(*) "NB_OCCURENCES"
           from ROGER_DUPLICATE t
          group by t.id
         having count(*) > 1) loop
      
        dbms_output.put_line(r_roger_duplicate.id || ' - ' || r_roger_duplicate.nb_occurences || ' times');

        for q in
          ( select page, id from roger_duplicate where id = r_roger_duplicate.id ) loop
             dbms_output.put_line ('  Page '|| q.page );
        end loop;
      end loop;
       
      Exit;
    else
      rollback;
      dbms_output.put_line('-> rollback done'); 
    end if;

    mMainDetail := mMainDetail + 1;
    exit when mMainDetail >= 8000;
  end loop;
end;
/
spool off
