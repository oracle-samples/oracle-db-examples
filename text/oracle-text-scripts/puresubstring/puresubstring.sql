-- prototype of pure substring index using grams
-- user running this must have explicit CREATE TABLE permission (not through role)
-- index table created is <basetable>$<colname>$grams

drop table base;
create table base(id number primary key, text varchar2(2000));

insert into base values (1, 'the quick brown dog dog dog jumps over the lazy dog');
insert into base values (2, 'fox speedy beige dog jumped right over the dog');
insert into base values (3, 'the dogs and other animals jump quickly');
insert into base values (4, 'dog dog');


create or replace procedure create_ps_index(
    tablename varchar2,   -- table name to be indexed 
    colname   varchar2,   -- text column name
    key       varchar2    -- unique key column name (must be numeric)
) is
  p             number;
  gram_size     number := 3;
  gram	        varchar2(255);
  sqlq	        varchar2(4000);
  csr 	        sys_refcursor;
  v_id	        number;
  v_text        clob;
  tab_not_exist exception;
  pragma        exception_init(tab_not_exist, -942);
begin
  -- none of this is SQL injection safe - doesn't matter much if run by owner
  begin
     execute immediate ('drop table '||tablename||'$'||colname||'$tmp');
  exception when tab_not_exist then null;
  end;
  execute immediate ('create table '||tablename||'$'||colname||'$tmp (gram varchar2('||to_char(gram_size*4)||'), id number, pos number)');
  sqlq := 'select '||key||' as id, '||colname||' as text from '||tablename; 
  open csr for sqlq;
  loop
    fetch csr into v_id, v_text;
    exit when csr%NOTFOUND;
    p := 1;
    while p <= ( length(v_text) ) loop
      gram := substr(v_text, p, gram_size);
      execute immediate 'insert into '||tablename||'$'||colname||'$tmp values (:1, :2, :3)' using gram, v_id, p;
      p := p + 1;
    end loop;
  end loop;
  begin
     execute immediate ('drop table '||tablename||'$'||colname||'$grams');
  exception when tab_not_exist then null;
  end;
  execute immediate ('create table '||tablename||'$'||colname||'$grams (data blob check (data is json format oson))'); 
  sqlq := '
insert into '||tablename||'$'||colname||'$grams 
    select json_object(gram,
        ''posting'' : json_arrayagg(
            json_object(''id'' : id, ''pos'' : parray returning json)
        )  
    returning json)
    from (
        select gram, id, json_arrayagg(pos) parray
        from '||tablename||'$'||colname||'$tmp
        group by gram, id
        )
  group by gram';
  execute immediate sqlq;
  execute immediate 'drop table '||tablename||'$'||colname||'$tmp';
  execute immediate 'create index '||tablename||'$'||colname||'$gidx on '||tablename||'$'||colname||'$grams g(g.data.gram)';
end;
/

exec create_ps_index('base', 'text', 'id')

select json_serialize(data) from base$text$grams g where g.data.gram.string() in ('dog', 'fox');

-- search procedure
-- currently uses DBMS_OUTPUT.PUT_LINE to display lines from the base table

-- ideally need to turn this into a table function returning IDs or ROWIDs

create or replace procedure ps_search (tablename varchar2, colname varchar2, key varchar2, searchterm varchar2) is
  gram_size     number := 3;
  sgram         varchar2(255);
  i 		number;
  cnt           integer;
  csr 	        sys_refcursor;
  sqlf		varchar2(4000);
  sql1          varchar2(4000);
  sql2		varchar2(4000);
  sql3		varchar2(4000);
  v_id	        number;
  v_text        clob;

begin
  cnt := floor( (length(searchterm)+2)/gram_size );

  sql1 := '
with postings as (
select gram, id, pos from '||tablename||'$'||colname||'$grams g
  nested data columns (
    gram,
    nested posting[*] columns (
      id,
      nested pos[*] columns (pos path ''$'')
    ) 
  ) 
)';
  sql2 := ' select distinct base.' || key || ' as id, substr(base.' || colname || ',1, 60) as text from ' || tablename || ' base, ';
  sql3 := ' where base.' || key || ' = t1.id and ';

  -- sql2 := 'select t1.id from ';
  -- sql3 := 'where ';


  i := 1;
  while i <= cnt loop
    sgram := substr(searchterm, i*gram_size - (gram_size-1), gram_size);

    if length(sgram) < gram_size then
      sgram := sgram || '%';
    end if;

    if i > 1 then sql2 := sql2 || chr(10) || ','; end if;
    sql2 :=  sql2 || ' postings t' ||i;

    if i > 1 then 
      sql3 := sql3 || chr(10) || ' and t' ||i|| '.pos = t' ||(i-1)|| '.pos + 3 and '; 
      sql3 := sql3 || chr(10) || 't'||i||'.id = t'||(i-1)||'.id and ';
    end if;

    sql3 := sql3 || chr(10) ||' t'||i||'.gram like '''||sgram||'''';

    i := i + 1;
 
  end loop;

  sqlf := sql1 || chr(10) || sql2 || chr(10) || sql3 || ' order by base.' || key;

  dbms_output.put_line(sqlf);

  open csr for sqlf;
  loop
    fetch csr into v_id, v_text;
    exit when csr%NOTFOUND;
    dbms_output.put_line('ID: '||v_id||' Text: '||v_text);
  end loop;
end;
/
list
show errors
