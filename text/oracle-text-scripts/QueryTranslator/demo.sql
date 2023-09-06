set serveroutput off
set linesize 132

@test.sql

select * from avtest where contains(text, 'dog cat') > 0;

select parser.simplesearch('dog cat') from dual;

select   * from avtest
where    contains( text, parser.simplesearch('dog cat') ) > 0

select   score(1), text from avtest
where    contains( text, parser.simplesearch('dog cat'), 1 ) > 0
order by score(1) desc;

select   score(1), text from avtest
where    contains( text, parser.simplesearch('+dog cat'), 1) > 0
order by score(1) desc;

select   score(1), text from avtest
where    contains( text, parser.simplesearch('cat +"sheep cow'), 1) > 0
order by score(1) desc;

select parser.orsearch('dog cat') from dual;
select parser.phrasesearch('dog cat') from dual;

select parser.progrelax('cat sheep cow') from dual;

select   score(1), text from avtest
where    contains( text, parser.progrelax('cat sheep cow"'), 1) > 0
order by score(1) desc;


select   score(1), text from avtest
where    contains( text, parser.simplesearch('cat +"sheep cow"'), 1) > 0
order by sco
select parser.simplesearch('cat seca:(dog)) from dual;

select parser.simplesearch('cat seca:dog "rabbit') from dual;w

select * from avtest where text like '%NT%';

select * from avtest where contains (text, 'windows nt') > 0;

select * from avtest where contains (text, '{windows} {nt}') > 0;

select * from avtest where contains (text, '{nt%}') > 0;

select * from avtest where contains (text, '{nt}%') > 0;

select * from avtest where contains (text, 'nt%') > 0;

select parser.simplesearch('windows nt%') from dual;

exec parser.setIndexName('avtestindex2')
