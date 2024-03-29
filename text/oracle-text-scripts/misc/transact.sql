drop table text_test;

create table text_test
(
INDEXED_TEXT VARCHAR2(1000)
)
;

-- Insert test data

insert into text_test values ('BUGS BUNNY') ;

commit ;

-- Create substring index preference

exec ctx_ddl.drop_preference('ms_wordlist')

begin
CTX_DDL.CREATE_PREFERENCE( 'ms_wordlist' , 'BASIC_WORDLIST' );
CTX_DDL.SET_ATTRIBUTE( 'ms_wordlist', 'SUBSTRING_INDEX', 'FALSE' );
CTX_DDL.SET_ATTRIBUTE( 'ms_wordlist', 'PREFIX_INDEX', 'TRUE' );
end;
/

-- Create the index

create index text_test_ctx on text_test ( indexed_text )
indextype is ctxsys.context
parameters
( 'wordlist ms_wordlist
stoplist ctxsys.empty_stoplist
transactional'
) ;

-- Search for a synchronized row using a wildcard

select indexed_text
from text_test
where contains ( indexed_text, 'BUG%') > 0 ;

-- Search for a synchronized row using non wildcard

select indexed_text
from text_test
where contains ( indexed_text, 'BUGS') > 0 ;

-- Insert more test data

insert into text_test values ('DONALD DUCK') ;
insert into text_test values ('MICKEY MOUSE') ;

commit ;

-- Search for non synchronized row using a wildcard

select indexed_text
from text_test
where contains ( indexed_text, 'MICK%') > 0 ;

- Search for non synchronized row using a non wildcard

select indexed_text
from text_test
where contains ( indexed_text, 'MICKEY') > 0 ;

-- Sync the index

exec ctx_ddl.sync_index('text_test_ctx');

-- Search using the wildcard again

select indexed_text
from text_test
where contains ( indexed_text, 'MICK%') > 0 ;

