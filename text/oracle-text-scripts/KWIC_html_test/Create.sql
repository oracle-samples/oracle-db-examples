create user testuser identified by testuser default tablespace users temporary tablespace temp;

grant connect, resource, ctxapp to testuser;

connect testuser/testuser

create table EmailArchive (
 PK NUMBER,
 FOLDER VARCHAR2(255),
 SUBJECT VARCHAR2(255),
 MAILDATE DATE,
 MAILTO VARCHAR2(255),
 MAILFROM VARCHAR2(255),
 MAILCC VARCHAR2(255),
 TEXT CLOB);

insert into emailarchive values (1, 'INBOX', 'The QB Fox', '10-JUL-2002','john.smith@oracle.com', 'roger.ford@oracle.com', null, 
'The quick brown fox jumps over the lazy dog.
The lazy dog was surprised to see a quick brown 
fox jumping over it, and thought to itself "goodness,
that looked like a wolf - or at least a brown fox -
jumping over me".');

insert into emailarchive values (1, 'INBOX', 'Now is the time...', '11-JUL-2002','roger.ford@oracle.com', 'john.smith@oracle.com', null, 
'Now is the time for all good men to come to the aid of the party.
The party is not doing very well at the moment as it has run out of
drink, and most of the guests have gone home. What we need is
for someone to come along with more drink, and hopefully with a 
quick brown fox as a companion.
');

commit;

create index email_text on emailarchive(text)
indextype is ctxsys.context;

