-- create and populate table
create table pangrams (author varchar(20), tdata varchar2(80), inserted date);

insert into pangrams values ('Roger', 'The quick brown fox jumps over the lazy dog', sysdate);
insert into pangrams values ('John',  'Bright vixens jump; dozy fowl quack', sysdate);

-- create index, explain syntax
create index pangidx on pangrams(tdata) indextype is ctxsys.context;

-- show tables

-- simple query
select * from pangrams where contains(tdata, 'jump') > 0

-- with wild card
select * from pangrams where contains(tdata, 'jump%') > 0

-- fuzzy query
select * from pangrams where contains(tdata, 'fuzzy(foul)') > 0

-- mixed query, add AUTHOR 
and author='John'

-- mixed query, add INSERTED
and inserted > '01-DEC-22'

-- Load CSV of shoe reviews

select count(*) from shoe_reviews;

-- find that reviews are in mixed languages...

select reviewer_name, review_text from shoe_reviews;

-- no problem, can fix that...

-- find languages

-- add a language column to table
alter table shoe_reviews add (language varchar2(20));

exec ctx_ddl.create_preference('shoe_lex', 'AUTO_LEXER')
exec ctx_ddl.create_policy    ('shoe_policy', lexer => 'shoe_lex')

declare 
  outtab ctx_doc.language_tab;
  myclob clob;
begin
  for c in (select rowid, review_text from shoe_reviews) loop
     ctx_doc.policy_languages(
       policy_name => 'SHOE_POLICY', 
       document    => c.review_text,
       restab      => outtab );
     for x in (select language, score 
                from table(outtab)
                order by score desc
                fetch next 1 rows only ) loop
        update shoe_reviews set language = x.language where rowid = c.rowid;
     end loop;
   end loop;
end;
/

select reviewer_name, language, review_text from shoe_reviews

where language != 'american'


exec ctx_ddl.create_preference   ('shoe_ds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute       ('shoe_ds', 'COLUMNS', 'reviewer_name, review_text, review_rating')

--exec ctx_ddl.create_preference   ('shoe_lex', 'AUTO_LEXER')

exec ctx_ddl.create_section_group('shoe_sg', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_ndata_section   ('shoe_sg', 'name', 'reviewer_name')

create index shoe_index on shoe_reviews (review_text)
indextype is ctxsys.context
parameters ('
  datastore     shoe_ds
  lexer         shoe_lex
  section group shoe_sg
');

-- Let's do a simple search

select review_text from shoe_reviews 
where contains (review_text, 'adidas') > 0;

select reviewer_name, review_text from shoe_reviews 
where contains (review_text, 'adidas', 1) > 0
order by score(1) desc;

-- Now a name search using our defined NAME section. Also introduces SCORE(1)

select reviewer_name from shoe_reviews 
where contains (review_text, 'NDATA(name, Vandike Karlos)', 1) > 0
order by score(1) desc;

-- can of course combine them:

select reviewer_name, review_text from shoe_reviews 
where contains (review_text, 'adidas AND NDATA(name, Vandike Karlos)', 1) > 0;


-- Now let's get clever. Let's look at Sentiments. Find positive reviews of Adidas

select ctx_doc.sentiment_aggregate('shoe_index', rowidtochar(rowid)),
       review_text
from   SHOE_REVIEWS
where  contains (review_text, 'adidas') > 0
order by 1 desc;

-- and negative

select ctx_doc.sentiment_aggregate('shoe_index', rowidtochar(rowid)),
       review_text
from   SHOE_REVIEWS
where  contains (review_text, 'adidas') > 0
and    ctx_doc.sentiment_aggregate('shoe_index', rowidtochar(rowid)) < 0
order by 1;

-- Now look at indexing external files in the object store.

exec dbms_cloud.DROP_EXTERNAL_TEXT_INDEX('mydocs')

begin
    for c in (select object_name from table (dbms_cloud.list_objects (
            credential_name => 'mycredential',
            location_uri    => 'https://objectstorage.uk-london-1.oraclecloud.com/n/lrxqmecwz64w/b/mydocs/o/'))) LOOP
        dbms_output.put_line(c.object_name);
    end loop;
end;


begin
    dbms_cloud.create_external_text_index (
        credential_name => 'mycredential',
        location_uri    => 'https://objectstorage.uk-london-1.oraclecloud.com/n/lrxqmecwz64w/b/mydocs/o/',
        index_name      => 'mydocs',
        format          => JSON_OBJECT('refresh_rate' value '1')
    );
end;

select * from mydocs$txtidx

select * from mydocs$txtidx where contains (object_name, 'jump%') > 0;

select object_name, ctx_doc.snippet('mydocs$idx', rowid, 'jump%', starttag=>'<<', endtag=>'>>', separator=>'...')
from   mydocs$txtidx
where  contains (object_name, 'jump%') > 0;

-- cleanup:
drop table pangrams;
drop table shoe_reviews;
drop table sdw$err$_shoe_reviews;

exec dbms_cloud.drop_external_text_index('mydocs')

exec ctx_ddl.drop_preference     ('shoe_ds')
exec ctx_ddl.drop_preference     ('shoe_lex')
exec ctx_ddl.drop_section_group  ('shoe_sg')

exec ctx_ddl.drop_policy          ('shoe_policy')

Pre-auth URLs
https://objectstorage.uk-london-1.oraclecloud.com/p/vRAG413lasCswEvY6U_yw1Rj1VVGsW4Bh7mAn5NR0i3w3CezdMOzmzPg645t80Oe/n/lrxqmecwz64w/b/mydocs/o/pangrams.txt
https://objectstorage.uk-london-1.oraclecloud.com/p/LGKPb11NniMq5q1X8zigiBGZz-LtmAwS_vJsjTIfPd_0lCXg4_xZJ9ymYijjW8XI/n/lrxqmecwz64w/b/mydocs/o/pangram.csv
https://objectstorage.uk-london-1.oraclecloud.com/p/HLIDVgJ5mFfWRv5DkapZfXdTBgewseMj8qJwoGo6iDUiR1idRLCdT3_mo4AIv0sl/n/lrxqmecwz64w/b/mydocs/o/pangrams.json
https://objectstorage.uk-london-1.oraclecloud.com/p/xR2ZoEPiVocIIvPv2qt7TqagEfFL-m7NoMp6Px0WDm8Wb04qWs9xANCPwiegPrbV/n/lrxqmecwz64w/b/mydocs/o/letter.txt
