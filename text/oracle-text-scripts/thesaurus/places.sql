drop table places;

create table places (key varchar2(2000));

insert into places values ('KHEIS SIYANDA NORTHERN_CAPE SOUTH_AFRICA');

exec ctx_ddl.drop_preference  ('plex')
exec ctx_ddl.create_preference('plex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('plex', 'PRINTJOINS', '_')

create index placesindex on places(key)
indextype is ctxsys.context
parameters ('lexer plex')
/

select key from places where contains (key, 'KHEIS AND NORTHERN_CAPE') > 0;

exec ctx_thes.drop_thesaurus('places')
exec ctx_thes.create_thesaurus('places')

exec ctx_thes.create_relation('places', 'NORTHERN_CAPE', 'SYN', 'NCAPE')
exec ctx_thes.create_relation('places', 'S_AFRICA', 'SYN', 'SOUTH_AFRICA')

-- original query would have been "kheis, S Africa"

select key from places where contains (key, 'NEAR( (NORTHERN_CAPE, SOUTH_AFRICA), 99, TRUE )') > 0;

select key from places where contains (key, 'NEAR( (SYN(ncape), SOUTH_AFRICA), 99, TRUE )') > 0;
