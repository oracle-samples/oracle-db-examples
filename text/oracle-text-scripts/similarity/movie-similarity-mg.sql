--
-- Setup
--

-- This object will be used to return the similar movies.
create or replace type obj_similar_movie as object (
        score       number,
        movie_id    number,
        title       varchar2(4000)
        );   
/

-- Start clean. Drop tables and indexes.
drop table movie_similarity;

begin
  ctx_ddl.drop_section_group('MOVIE_SECTION_GROUP');
end;
/

begin
  ctx_ddl.drop_preference('MOVIE_DATASTORE');
end;
/

-- Create a movie_similarity table. This table will be used for deriving similar movies
-- JSON fields are simplified and formatted so that they are ready for text analytics

-- Extract arrays - turn into comma separted fields
-- Crew will have duplicate names (e.g. a director may be a writer). Must be fixed.
create table movie_similarity as
    select
        movie_id,
        year,
        title,
        translate(genre, '["]', ' ') as genre,
        translate(json_query(m.crew, '$[*].names' with array wrapper),
            '["]', ' ') as crew,        
        translate(cast, '["]', ' ') as cast,
        summary
    from movie m;

-- setup up text analytics
begin
  ctx_ddl.create_preference('MOVIE_DATASTORE','MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('MOVIE_DATASTORE','COLUMNS','genre, year, cast, crew, summary, title');
end;
/

begin
  ctx_ddl.create_section_group('MOVIE_SECTION_GROUP','AUTO_SECTION_GROUP');
end;
/

-- the index is on a single column
-- yet it is a multi-column data store.
-- The "virtual/composite" column is associated with the single summary column here?
-- And, it's okay for the columns comprising the index contain JSON?
-- How is this impacted if there is repetition - e.g. directors/producer/writer may be the same person
create index movie_text_index
  on movie_similarity (summary)
  indextype is ctxsys.context
  parameters('
    datastore       MOVIE_DATASTORE
    section group   MOVIE_SECTION_GROUP
  ')
/

-- This table function can be used to get the 10 similar movies
create or replace function get_similar_movies (
    -- Pass a movie_id or title
    -- If you pass both, and they don't match, then you may get unexpected results
    movie_id  in number default null,   
    title     in varchar2 default null 
) 
return t_similar_movie pipelined as 

    contains_clause clob;    
    l_movie_id      number;
    l_title         varchar2(1000);
    movie_rec       movie_similarity%rowtype;
    similar_movies  t_similar_movie;
    similar_movie_rec obj_similar_movie := obj_similar_movie(null, null, null);
    year_clause     clob;

begin

    -- Validate movie_id and title by querying the movie_similarity table
    l_movie_id  := movie_id;
    l_title     := title;
    
    -- This query will return the first valid row that matches the query
    begin
        select *
        into movie_rec 
        from movie_similarity 
        where 
            movie_id = l_movie_id or
            title    = l_title
        fetch first row only;
            
    l_movie_id := movie_rec.movie_id;
    l_title    := movie_rec.title;
    
    -- No movies - so bail
    exception when no_data_found then
        return;
    end;

    -- Built the contains calause for the query. Here's the template.    
    contains_clause := '(year_clause) WITHIN year )*.2 
                          ACCUM (genre_clause) WITHIN genre  
                          ACCUM (cast_clause) WITHIN cast  
                          ACCUM (crew_clause) WITHIN crew';
                          --ACCUM (title_clause) WITHIN title';                                        
                                                        
    -- Let's weigh years. Movies that are closer in release date will have a higher score
    -- Years in general have a lower score compared to the other fields 
    -- (see template above - its impact is reduced by 20%_
    year_clause := '((' || to_char(movie_rec.year-2) ||'*.25 OR '
                        || to_char(movie_rec.year-1) || '*.5 OR '
                        || to_char(movie_rec.year) ||'*1 OR '
                        || to_char(movie_rec.year+1) || '*.5 OR ' 
                        || to_char(movie_rec.year+2) || '*.2 )';
    contains_clause := replace(contains_clause, 'year_clause', year_clause);    
    
    -- Simple replacement for other fields
    -- We're adding the movie's genre, cast and crew
    -- Should summary be added here? Enabling the summaries to be compared?
    -- Use "ABOUT" with summary?
    contains_clause := replace(contains_clause, 'genre_clause', nvl(movie_rec.genre, '""'));
    contains_clause := replace(contains_clause, 'cast_clause', nvl(movie_rec.cast, '""'));
    contains_clause := replace(contains_clause, 'crew_clause', nvl(movie_rec.crew,'""'));
    --contains_clause := replace(contains_clause, 'title_clause', movie_rec.title);

    -- Now that the query has been built, run it.
    -- Loop over the result and return one row at a time using "pipe"
    -- Will return the top 10 movies
    for c in (  
        select 
            score(1) as score, 
            movie_id, 
            title     
        from movie_similarity 
        where contains(summary, contains_clause, 1) > 0 
          and movie_id != l_movie_id
        order by score(1) desc
        fetch first 10 rows only)
    
    loop
        similar_movie_rec.score     := c.score;
        similar_movie_rec.movie_id  := c.movie_id;
        similar_movie_rec.title     := c.title;
        
        pipe row (similar_movie_rec);
    end loop;
                
    return;
  
end get_similar_movies;
/


-- Try it using a title or a movie_id. Looks pretty good!
select *
from table(get_similar_movies(title => 'Frozen'));

select *
from table(get_similar_movies(movie_id => 3244)); --> The Godfather
