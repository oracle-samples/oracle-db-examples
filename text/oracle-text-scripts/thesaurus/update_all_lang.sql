SET SERVEROUTPUT OFF
begin
  Dbms_Output.Enable ('localhost', 1599, 'WE8ISO8859P1');
end;
/

drop index aliasind;
create index aliasind on aliases (area_id, lang);

create index elw_area_id_ind on eloc_work (area_id);
create index elw_area_name_ind on eloc_work (area_name);

set timing on

declare
  varea_id number;
  twork    varchar2(4000);
  vkey     varchar2(4000);
  conj     varchar2(2) := '';
  counter number := 0;
begin
  for l in (select id, lang from langids ) loop

    dbms_output.put_line('processing language '|| l.lang);

    for c in (select area_id, area_name, level1_area_id, level2_area_id, level3_area_id, level4_area_id, level5_area_id from eloc_work) loop

      -- dbms_output.put_line('Area name: '|| c.area_name || 'Area ID: ' || c.area_id||' Levels: '|| c.level1_area_id||', '||c.level2_area_id||', '||c.level3_area_id||', '||c.level4_area_id||', '||c.level5_area_id);

      twork := '';
      conj := '';

      if c.level5_area_id is not null then
        
        counter := 0;
        for a in (select alias from aliases al where al.area_id = c.level5_area_id and al.lang = l.lang) loop
          twork := twork || conj || a.alias;
          conj := ',';
        end loop;
        if counter = 0 then
          for a in (select area_name from eloc_work e where e.area_id = c.level5_area_id ) loop
            twork := twork || conj || a.area_name;
            conj := ',';
          end loop;
        end if;

      end if;
      if c.level4_area_id is not null then
        
        counter := 0;
        for a in (select alias from aliases al where al.area_id = c.level4_area_id and al.lang = l.lang) loop
          twork := twork || conj || a.alias;
          conj := ',';
        end loop;
        if counter = 0 then
          for a in (select area_name from eloc_work e where e.area_id = c.level4_area_id ) loop
            twork := twork || conj || a.area_name;
            conj := ',';
          end loop;
        end if;

      end if;
      if c.level3_area_id is not null then
        
        counter := 0;
        for a in (select alias from aliases al where al.area_id = c.level3_area_id and al.lang = l.lang) loop
          twork := twork || conj || a.alias;
          conj := ',';
        end loop;
        if counter = 0 then
          for a in (select area_name from eloc_work e where e.area_id = c.level3_area_id ) loop
            twork := twork || conj || a.area_name;
            conj := ',';
          end loop;
        end if;

      end if;
      if c.level2_area_id is not null then
        
        counter := 0;
        for a in (select alias from aliases al where al.area_id = c.level2_area_id and al.lang = l.lang) loop
          twork := twork || conj || a.alias;
          conj := ',';
        end loop;
        if counter = 0 then
          for a in (select area_name from eloc_work e where e.area_id = c.level2_area_id ) loop
            twork := twork || conj || a.area_name;
            conj := ',';
          end loop;
        end if;

      end if;
      if c.level1_area_id is not null then
        
        counter := 0;
        for a in (select alias from aliases al where al.area_id = c.level1_area_id and al.lang = l.lang) loop
          twork := twork || conj || a.alias;
          conj := ',';
        end loop;
        if counter = 0 then
          for a in (select area_name from eloc_work e where e.area_id = c.level1_area_id ) loop
            twork := twork || conj || a.area_name;
            conj := ',';
          end loop;
        end if;

      end if;

      if length(twork) > 0 then

        -- dbms_output.put_line('Writing - Area: '||c.area_name || ' key: '|| twork || ' Lang ID: '||l.id);

        insert into eloc_part select 
           AREA_ID,
           AREA_NAME,
           twork,
           aliases,
           LANG_CODE,
           ADMIN_LEVEL,
           LEVEL1_AREA_ID,
           LEVEL2_AREA_ID,
           LEVEL3_AREA_ID,
           LEVEL4_AREA_ID,
           LEVEL5_AREA_ID,
           LEVEL6_AREA_ID,
           LEVEL7_AREA_ID,
           CENTER_LONG,
           CENTER_LAT,
           POSTAL_CODE,
           COUNTRY_CODE_2,
           REAL_NAME,
           GOVERNMENT_CODE,
           ALIAS_LIST,
           l.id
        from eloc_work w
        where w.area_id = c.area_id;

      end if;

    end loop;
  end loop;
end;
/

