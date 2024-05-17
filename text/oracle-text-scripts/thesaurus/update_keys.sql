declare
  varea_id number;
  twork varchar2(4000);
  vkey  varchar2(4000);
  conj  varchar2(2) := '';
  counter number := 0;
begin
  for c in (select area_id, area_name, aliases, 
            level1_area_id, level2_area_id, level3_area_id, level4_area_id, level5_area_id, level6_area_id, level7_area_id
            from eloc_work) loop
    varea_id := c.area_id;
    counter := counter + 1;
    begin
    if c.level7_area_id is not null then
       select area_name || ',' || aliases into twork from eloc_work where area_id = c.level7_area_id;
       --dbms_output.put_line('vkey1:  '||vkey);
       --dbms_output.put_line('twork: '||twork);
       vkey := vkey || conj || twork;
       conj := ',';
    end if;
    if c.level6_area_id is not null then
       select area_name || ',' || aliases into twork from eloc_work where area_id = c.level6_area_id;
       --dbms_output.put_line('vkey2:  '||vkey);
       --dbms_output.put_line('twork: '||twork);
       vkey := vkey || conj || twork;
       conj := ',';
    end if;
    if c.level5_area_id is not null then
       select area_name || ',' || aliases into twork from eloc_work where area_id = c.level5_area_id;
       --dbms_output.put_line('vkey3:  '||vkey);
       --dbms_output.put_line('twork: '||twork);
       vkey := vkey || conj || twork;
       conj := ',';
    end if;
    if c.level4_area_id is not null then
       select area_name || ',' || aliases into twork from eloc_work where area_id = c.level4_area_id;
       --dbms_output.put_line('vkey4:  '||vkey);
       --dbms_output.put_line('twork: '||twork);
       vkey := vkey || conj || twork; 
       conj := ',';
    end if;
    if c.level3_area_id is not null then
       select area_name || ',' || aliases into twork from eloc_work where area_id = c.level3_area_id;
       vkey := vkey || conj || twork;
       conj := ',';
    end if;
    if c.level2_area_id is not null then
       select area_name || ',' || aliases into twork from eloc_work where area_id = c.level2_area_id;
       vkey := vkey || conj || twork;
       conj := ',';
    end if;
    if c.level1_area_id is not null then
       select area_name || ',' || aliases into twork from eloc_work where area_id = c.level1_area_id;
       vkey := vkey || conj || twork;
       conj := ',';
    end if;
    update eloc_work set key = vkey where area_id = c.area_id;   
    --dbms_output.put_line(' ** RESET ** ');
    vkey := '';
    conj := '';
--    if counter > 1000 then 
--      exit;
--    end if;
    exception when others then
      dbms_output.put_line('Overflow for area_name: '||c.area_name);
    end;
  end loop;
end;
/

create table langIds as select lang from aliases group by lang order by lang;

alter table langids add (id number);
update langids set id = rownum;

alter table aliases add (langid number);

update aliases a set langid = (select id from langids l where l.lang = a.lang);
