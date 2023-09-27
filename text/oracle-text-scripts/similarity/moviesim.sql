create or replace procedure get_similar_movie(moviename varchar2) is
  m_id     number;
  themes   ctx_doc.theme_tab;
  
  v_genre    varchar2(4000);
  v_year     number;
  v_cast     varchar2(4000);
  v_crew     varchar2(4000);

  cont       clob;  -- we'll build our CONTAINS clause here
  conj       varchar2(10);  -- conjunction between repeated elements
begin
  begin
    select movie_id into m_id from movietab where title = moviename;
  exception when no_data_found then
     dbms_output.put_line('No movie with name ' ||moviename|| ' found');
  end;
 
  select genre, year, cast, crew into v_genre, v_year, v_cast, v_crew from movietab where movie_id = m_id;
  cont := '';
  -- Year lookup : same year scores 1, previous or next year scores 0.5, two years away scores 0.2
  cont := cont || '((' || to_char(v_year-2) ||'*.25 OR '|| to_char(v_year-1) || '*.5 OR '|| to_char(v_year) ||'*1 OR '|| to_char(v_year+1) || '*.5 OR ' || to_char(v_year+2) || '*.2 )';
  cont := cont || ' WITHIN year )*.2';
  -- pl(cont); 

  -- genre and cast are JSON arrays
  cont := cont || ' ACCUM (';
  conj := '';
  for csr in ( select jt.gen from movietab m, 
                json_table( genre, '$[*]' columns gen path '$') jt
                where movie_id = m_id ) loop
    -- pl(csr.gen);
    cont := cont || conj || csr.gen;
    conj := ' , ';
  end loop;
  cont := cont || ') WITHIN genre ';

  cont := cont || ' ACCUM (';
  conj := '';
  for csr in ( select jt.cst from movietab m, 
                json_table( cast, '
$[*]' columns cst path '$') jt
                where movie_id = m_id ) loop
    -- pl(csr.cst);
    cont := cont || conj || csr.cst;
    conj := ' , ';
  end loop;
  cont := cont || ') WITHIN cast ';
  pl (cont);

  -- director is buried in the CREW array
  cont := cont || ' ACCUM (';
  conj := '';
  for csr in ( 
        select jt.nam from movietab, 
            json_table (crew, '$[*]' columns
                job path '$.job',
                nested path '$.names[*]' columns (
                    nam path '$[*]' 
            ) ) jt
    where jt.job = 'producer' ) loop
    cont := cont || conj || csr.nam;
    conj := ' , ';
  end loop;
  cont := cont || ') WITHIN crew ';

  -- pl(scont);

  -- now run the CONTAINS query that we've built
  for csr in (
       select * from (
         select score(1) scr, movie_id, title 
         from movietab 
         where contains(summary, cont, 1) > 0 
         order by score(1) desc
         ) where rownum <= 10
       ) loop
    pl('Score: ' || csr.scr|| ' Title:' || csr.title);
  end loop;

end;
/

-- select movie_id, genre, cast from movietab where title='The Godfather';

-- select gen from movietab g nested genre[*] columns (gen path '$') where movie_id = 3244;

exec get_similar_movie('Rocky')
-- select title, year, crew, cast from movietab where title in ('Rocky', 'Assault on Precinct 13', 'The Choirboys')
