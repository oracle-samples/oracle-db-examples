drop table base_ngrams;
create table base_ngrams (gram varchar2(10), id number, pos number);

create or replace procedure create_ps_index is
  p         number;
  gram_size number := 3;
  gram	    varchar2(10);
begin
  for c in (select movie_id as id, summary as text from movietab) loop
    p := 1;
    while p <= ( length(c.text)-(gram_size -1) ) loop
      gram := substr(c.text, p, gram_size);
      p := p + 1;
      -- dbms_output.put_line('id: '||c.id||' gram: '||gram||' pos:'||p);
      insert into base_ngrams values (gram, c.id, p);
    end loop;
  end loop;
end;
/

exec create_ps_index

drop table json_grams force;

create table json_grams (data json);

insert into json_grams
    select json_object(gram,
        'posting' : json_arrayagg(
            json_object('id' : id, 'pos' : parray returning json)
        )  
    returning json)
    from (
        select gram, id, json_arrayagg(pos) parray
        from base_ngrams
    group by gram, id
    )
group by gram;
 
select sum(dbms_lob.getlength(json_serialize(data returning clob)))/1024/1024 from json_grams;
select sum(length(summary))/1024/1024 from movietab;

select substr(json_serialize(data returning clob),1,120) from json_grams g where g.data.gram.string() = 'tra'
