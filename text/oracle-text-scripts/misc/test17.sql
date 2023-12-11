drop table x;

create table x (t varchar2(2000));

insert into x values ('V1-Vision Corporation');

-- create default index
create index xi on x(t) indextype is ctxsys.context;

-- examine the tokens generated in the index
select token_text from dr$xi$i;

-- doesn't work: equiv to "v1 MINUS vis%"
select * from x where contains (t, 'V1-Vis%') > 0;

-- doesn't work: % outside of term expands to any word
select * from x where contains (t, '{V1-Vis}%') > 0;

-- does work in this case because minus is a separator character
select * from x where contains (t, 'V1 Vis%') > 0;

-- works in all cases
select * from x where contains (t, 'V1\-Vis%') > 0;

-- now create index where "-" is a PRINTJOINS character
exec ctx_ddl.drop_preference  ('mylex')
exec ctx_ddl.create_preference('mylex', 'BASIC_LEXER')
exec ctx_ddl.set_attribute    ('mylex', 'PRINTJOINS', '-')

drop index xi;
create index xi on x(t) indextype is ctxsys.context parameters ('lexer mylex');

-- examine the tokens generated in the index
select token_text from dr$xi$i;

-- doesn't work: equiv to "v1 MINUS vis%"
select * from x where contains (t, 'V1-Vis%') > 0;

-- doesn't work: % outside of term expands to any word
select * from x where contains (t, '{V1-Vis}%') > 0;

-- this now DOESN'T work as minus is part of the token
select * from x where contains (t, 'V1 Vis%') > 0;

-- works in all cases
select * from x where contains (t, 'V1\-Vis%') > 0;

For all cars except Classics:

Competitors must use Yokohama 185/60 R13 A048R, medium (M) compound or Yokohama 170/5500R13 N2968 (M) marked ¡°For competition use only) A048R.  These tyre are identical apart for the markings on the side wall. 

A048Rs are no longer E-marked for road use, and for some reason the sizing designation changed when they became competition tyres, though as said the tyres are identical otherwise.
