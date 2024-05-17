set echon on

drop table themetest;

create table themetest (pk number primary key, text varchar2(4000));
insert into themetest values (1, '
Ken Lay announced today that he has resigned from Enron''s Board of Directors.
His resignation is effective immediately.
'||chr(10)||'
In a press release, Ken said, "I want to see Enron survive and successfully
emerge from reorganization. Due to the multiple inquiries and investigations,
some of which are focused on me personally, I believe that my involvement has
become a distraction to achieving this goal." 
'||chr(10)||'
He added, "My concern is for current and former Enron employees and other
stakeholders, and I feel that it is in their best interest for me to step down
from the Board."
');

commit;

exec ctx_ddl.drop_preference('mylexer')
exec ctx_ddl.create_preference('mylexer', 'basic_lexer')
exec ctx_ddl.set_attribute('mylexer', 'index_themes', 'true')

create index themeindex on themetest (text) indextype is ctxsys.context
parameters ('lexer mylexer');

-- If you uncomment this it will show you the themes indexed for the document:
select token_text from dr$themeindex$i where token_type=1;

-- We're getting to get all the themes for the document with primary key 1:

-- We need a table to put the results into (can also fetch into a PL/SQL structure)

drop table theme_table;

create table theme_table
( query_id number, 
  theme    varchar2(2000),
  weight   number);

begin
  ctx_doc.themes(
    index_name  => 'themeindex',
    textkey     => '1',
    restab      => 'theme_table',
    query_id    => 1,
    full_themes => FALSE,
    num_themes  => 50
  );
end;
/

column theme format a30
select theme, weight from theme_table order by weight desc;

-- Now get gists

-- First the generic gist

drop table gist_table;

create table gist_table
( query_id number,
  pov      varchar2(80),
  gist     CLOB
);

begin
  ctx_doc.gist(
     index_name => 'themeindex',
     textkey    => '1',
     restab     => 'gist_table',
     pov        => 'GENERIC'
  );
end;
/

select pov from gist_table;

select gist from gist_table where pov='GENERIC';

-- Now get the gist from the point of view of the theme EMPLOYEES

begin
  ctx_doc.gist(
     index_name => 'themeindex',
     textkey    => '1',
     restab     => 'gist_table',
     pov        => 'employees'
  );
end;
/

select gist from gist_table where pov='employees';
