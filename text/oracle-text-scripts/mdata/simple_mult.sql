set echo on

drop table users;
exec ctx_ddl.drop_section_group('mysg')

create table users
(username varchar2(30));

insert into users values ('john');
insert into users values ('mary');

exec ctx_ddl.create_section_group(group_name=>'mysg', group_type=>'xml_section_group');
exec ctx_ddl.add_mdata_section(group_name=>'mysg', section_name=>'rolename', tag=>'rolename');

create index users_ind on users (username) 
indextype is ctxsys.context
parameters ('section group mysg');

variable the_rowid varchar2(18);

begin
  select rowid into :the_rowid from users where username = 'john';
end;
/
exec ctx_ddl.add_mdata ('users_ind', 'rolename', 'dba', :the_rowid)
exec ctx_ddl.add_mdata ('users_ind', 'rolename', 'admin', :the_rowid)

begin
  select rowid into :the_rowid from users where username = 'mary';
end;
/
exec ctx_ddl.add_mdata ('users_ind', 'rolename', 'operator', :the_rowid)
exec ctx_ddl.add_mdata ('users_ind', 'rolename', 'enduser', :the_rowid)

select * from users where contains (username, 'mdata(rolename, operator)') > 0;

