begin
  ctx_ddl.create_preference('MOVIE_DST','MULTI_COLUMN_DATASTORE');
  ctx_ddl.set_attribute('MOVIE_DST','COLUMNS','genre, year, cast, crew, summary');
end;
/

begin
  ctx_ddl.create_section_group('MOVIE_SGP','AUTO_SECTION_GROUP');
end;
/

create index MOVIE
  on MOVIETAB
      (SUMMARY)
  indextype is ctxsys.context
  parameters('
    datastore       MOVIE_DST
    section group   MOVIE_SGP
  ')
/
 
