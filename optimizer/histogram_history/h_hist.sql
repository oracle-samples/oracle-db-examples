--
--
-- List histogram history for a given table/owner
--
-- Usage:  @h_hist table_name user_name
--         @h_hist table_name user        (to assume current username)
--
--
set linesize 250
set serveroutput on verify off

declare
  v_colnum     pls_integer;
  v_colname      varchar2(128);
  v_savetime         timestamp;
  v_savetime_text     varchar2(50);
  v_prevnumbuck     number(10);
  v_pprev_numbuck    number(10);
  v_tim_count  number(10);
  v_fmt        varchar2(100) := 'yyyy-dd-mm hh24:mi:ss';
  v_bucket_count_now      number(10);
  v_line       varchar2(1000);
  p_tabname  varchar2(200)  := upper('&1.');
  p_ownname  varchar2(200) := upper('&2.');

  cursor current_cols is
     select c.column_name,
            c.column_id,
            decode(s.histogram,'NONE','[Current: No Histogram]','[Current: '||nvl(s.histogram,'No Stats')||']') histogram,
            to_char(s.LAST_ANALYZED,v_fmt) last_analyzed, 
            s.num_buckets
     from   dba_tab_col_statistics s,
            dba_tab_columns c
     where  c.table_name = p_tabname
     and    c.owner      = p_ownname
     and    s.table_name  (+) = c.table_name
     and    s.owner       (+) = c.owner
     and    s.column_name (+) = c.column_name
     order by column_id;

  cursor distinct_tim is
     select distinct savtime,SAMPLE_DISTCNT
     from   sys.WRI$_OPTSTAT_HISTHEAD_HISTORY
     where  intcol# = v_colnum
     and    obj# = (select object_id from dba_objects where object_name = p_tabname and owner=p_ownname and object_type = 'TABLE')
     order by savtime;

  cursor distinct_col is
     select distinct intcol#, colname
     from   sys.WRI$_OPTSTAT_HISTHEAD_HISTORY
     where  obj# = (select object_id from dba_objects where object_name = p_tabname and owner=p_ownname and object_type = 'TABLE');

  cursor hh is
     select count(*) buckets
     from   sys.WRI$_OPTSTAT_HISTGRM_HISTORY
     where  obj# = (select object_id from dba_objects where object_name = p_tabname and owner=p_ownname and object_type = 'TABLE')
     and    intcol# = v_colnum
     and    savtime = v_savetime;
begin
   select decode(p_ownname,'USER',user,p_ownname) into p_ownname from dual;

   dbms_output.put_line('Table : '||p_ownname||'.'||p_tabname);
   for r in current_cols
   loop
      v_bucket_count_now := r.num_buckets;
      dbms_output.put_line('Column: '||rpad(substr(r.column_name,1,40),41)||'  Last analyzed: '||r.last_analyzed||' '||r.histogram);
      v_colnum := r.column_id;
      v_colname := r.column_name;
      v_tim_count := 0;
      v_pprev_numbuck := 0;
      for t in distinct_tim
      loop
        v_savetime := t.savtime;
        v_savetime_text := to_char(v_savetime,v_fmt);
        for h in hh
        loop
           v_prevnumbuck := h.buckets;
           if (v_tim_count = 0)
           then
              v_line := '-     '||v_savetime_text||' ';
           else
              if (v_pprev_numbuck != v_prevnumbuck) 
              then
                 dbms_output.put_line(v_line||to_char(v_pprev_numbuck,9999)||' -> '||to_char(v_prevnumbuck,9999)||' buckets CHANGE');
              else
                 dbms_output.put_line(v_line||to_char(v_prevnumbuck,9999) ||'          buckets');
              end if;
              v_pprev_numbuck := v_prevnumbuck;
           end if;
           v_line := '-     '||v_savetime_text||' ';
        end loop; 
        v_tim_count := v_tim_count + 1;
      end loop; 
      if (v_bucket_count_now>1)
      then
         if (v_bucket_count_now!=v_prevnumbuck)
         then
            dbms_output.put_line('-     '||r.last_analyzed||' '||to_char(v_prevnumbuck,9999)||' -> '||to_char(v_bucket_count_now,9999)||' buckets CHANGE');
         else
            dbms_output.put_line('-     '||r.last_analyzed||' '||to_char(v_bucket_count_now,9999)||' buckets');
         end if;
      else
         if (v_prevnumbuck>1)
         then
            dbms_output.put_line('-     '||r.last_analyzed||' '||to_char(v_prevnumbuck,9999)||' ->     0 buckets'||' CHANGE');
         else
            dbms_output.put_line('-     '||r.last_analyzed||'     0          buckets');
         end if;
      end if;
   end loop;
end;
/

