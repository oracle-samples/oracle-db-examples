set echo off

prompt SQL>  connect system/telstar
connect system/telstar

prompt SQL>  drop user flotest cascade;
drop user flotest cascade;

prompt SQL>  create user flotest identified by flotest default tablespace users temporary tablespace temp quota unlimited on users;
create user flotest identified by flotest default tablespace users temporary tablespace temp quota unlimited on users;

prompt SQL>  grant connect,resource,ctxapp,create any directory to flotest;
grant connect,resource,ctxapp,create any directory to flotest;

--prompt press enter..
--pause

prompt SQL>  connect flotest/flotest
connect flotest/flotest

prompt SQL>  create table docs( id number primary key, txt clob );
create table docs( id number primary key, txt clob );

prompt inserting document...

-- insert into docs values (1, 'From year 2008: 123A a random 90 The patient, I1234 Dorothy Smidt (ssn 123456789) is aged 103. At 92 years old (or 111 years of age, or age 112) she lived at 26 Fairfax Drive, Redwood City, CA 94062.' || chr(10) || '<p>' ||
'Her phone number is 415 506-2649 also written (415) 506-2649.'|| chr(10) ||
'She was born on 29th February 1982 and has a Ford Cougar car registration I1B X22Y . We gave here 22cc of insulin. 22 is not a code number but big numbers probaby are. Here''s a big number 123456 and another 098765432121 Ends. Author: roger.ford@oracle.com');

insert into docs values (1, 'Patient: Dorothy Smidt' || chr(10) || '<p>' ||
'Patient Number: 7362587' || chr(10) || '<p>' ||
'Admission Date: February 23 2010' || chr(10) || '<p>' ||
'Notes' || chr(10) || '<p>' ||
'Joanna (social security number 345123678) is aged 92. She presented with severe symptoms of fundango bicardialism on February 23. She was driven in from her home in Richmond, Virginia by her daughter in a vehicle with California license plate 5CRE8K78.' || chr(10) || '<p>' ||
'' || chr(10) || '<p>' ||
'She had been suffering these symptoms since 1993 and is 20 percent disabled.' || chr(10) || '<p>' ||
'' || chr(10) || '<p>' ||
'She was treated with 345ml of Flourestican (prescription ID 767CBR). This alleviated all symptoms and she was released on March 31.' || chr(10) || '<p> By: roger.ford@oracle.com <br>'
);

set long 50000
set pagesize 60

select txt from docs;

prompt SQL>  create table entities( id number primary key, ents clob );
create table entities( id number primary key, ents xmltype );

--prompt press enter...
--pause

prompt SQL>  exec ctx_entity.create_extract_policy( 'p1' );
exec ctx_entity.create_extract_policy( 'p1' );

prompt press enter to display file "dict.load"
-- pause

host cat dict.load

prompt press enter...
-- pause

prompt host ctxload -user flotest/flotest -extract -name p1 -file dict.load
host ctxload -user flotest/flotest -extract -name p1 -file dict.load

prompt press enter...
-- pause

declare
  mydoc clob;
  myresults clob;
begin

  --put input document into mydoc
  select txt into mydoc from docs where id=1;

  --add a new rule to identify increases (eg stock indices)

  ctx_entity.add_extract_rule('p1', 1,
    '<rule>'                                                          ||
      '<expression>'                                                  ||
         '([A-Z]+[0-9]+[A-Z0-9]*)'                     ||
      '</expression>'                                                 ||
      '<type refid="1">xalphanum_code</type>'                          ||
    '</rule>');

  ctx_entity.add_extract_rule('p1', 2,
    '<rule>'                                                          ||
      '<expression>'                                                  ||
         '([0-9]+[A-Z]+[A-Z0-9]*)'                     ||
      '</expression>'                                                 ||
      '<type refid="1">xalphanum_code</type>'                          ||
    '</rule>');

  ctx_entity.add_extract_rule('p1', 3,
    '<rule>'                                                          ||
      '<expression>'                                                  ||
         '(([A-Z]+[a-z]+) (Road|Street|St|Drive|Dr|Avenue|Ave|Blvd|Boulevard|Crescent|Cr))'                     ||
      '</expression>'                                                 ||
      '<type refid="1">xstreet</type>'                          ||
    '</rule>');
  
  ctx_entity.add_extract_rule('p1', 4,
    '<rule>'                                                          ||
      '<expression>'                                                  ||
         '((19\d\d)|(20[0-1]\d))' ||
      '</expression>'                                                 ||
      '<type refid="1">xyear</type>'                          ||
    '</rule>');
  
  ctx_entity.add_extract_rule('p1', 5,
    '<rule>'                                                          ||
      '<expression>'                                                  ||
         '([0-9]{10,20}|[0-9]{6,8})' ||
      '</expression>'                                                 ||
      '<type refid="1">xnum_code</type>'                          ||
    '</rule>');

  ctx_entity.add_extract_rule('p1', 7,
    '<rule>'                                                          ||
      '<expression>'                                                  ||
         '(aged|age) (9\d|1[0-2][0-9])' ||
      '</expression>'                                                 ||
      '<type refid="2">xage_over89</type>'                          ||
    '</rule>');

  ctx_entity.add_extract_rule('p1', 8,
    '<rule>'                                                          ||
      '<expression>'                                                  ||
         '(9\d|1[0-2][0-9]) ((years)|(yrs) old)|(of age)' ||
      '</expression>'                                                 ||
      '<type refid="1">xage_over89</type>'                          ||
    '</rule>');
  
  
  ctx_entity.compile('p1');

  --run extraction using policy p1
  ctx_entity.extract('p1', mydoc, null, myresults, 'ssn,phone_number,date,xstreet,city,zip_code,xalphanum_code,xname,xnum_code,xyear,xage_over89,email_address' );
  -- ctx_entity.extract('p1', mydoc, null, myresults );

  --save entities to table
  insert into entities values(1, xmltype(myresults));
  commit;

end;
.

list
/
prompt press enter...
pause

prompt SQL>  select * from entities;
select * from entities;

column type format a20
column text format a25
column source format a20

set echo on
 
select foo.offset, foo.text, foo.type, foo.source
from entities e,
xmltable( '/entities/entity'
PASSING e.ENTS
  COLUMNS 
    offset number       PATH '@offset',
    lngth number        PATH '@length',
    text   varchar2(50) PATH 'text/text()',
    type   varchar2(50) PATH 'type/text()',
    source varchar2(50) PATH '@source'
) as foo order by offset;


set echo off
set feedback off
prompt press enter...
-- pause

@proc_entities

set feedback 2

prompt SQL>  select entdemo.write_the_clob( entdemo.proc_entities( txt ), 'test1.html' ) from docs where id = 1;
select entdemo.write_the_clob( entdemo.proc_entities( txt ), 'test1.html', txt ) from docs;
