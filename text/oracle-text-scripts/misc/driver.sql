connect roger/telstar@local817
begin
  ctx_ddl.drop_preference ( 'my_user_datastore' );
end;
/
begin
  ctx_ddl.create_preference ( 'my_user_datastore', 'user_datastore' );
  ctx_ddl.set_attribute ( 'my_user_datastore', 'procedure','url_uds_proc' );
end;
/

begin
  ctx_ddl.drop_preference
    (
      preference_name => 'my_basic_lexer'
    );
end;
/
begin
  ctx_ddl.create_preference
    (
      preference_name => 'my_basic_lexer',
      object_name     => 'basic_lexer'
    );
  ctx_ddl.set_attribute
    (
      preference_name => 'my_basic_lexer',
      attribute_name  => 'index_text',
      attribute_value => 'true'
    );
  ctx_ddl.set_attribute
    (
      preference_name => 'my_basic_lexer',
      attribute_name  => 'index_themes',
      attribute_value => 'false');
end;
/

begin
  ctx_ddl.drop_section_group
    (
       group_name => 'my_basic_section_group'
    );
end;
/
begin
  ctx_ddl.create_section_group
    (
       group_name => 'my_basic_section_group',
       group_type => 'basic_section_group'
    );
  ctx_ddl.add_field_section
    (
      group_name   => 'my_basic_section_group',
      section_name => 'title',
      tag          => 'title',
      visible      => false /* this is the DEFAULT */
    );
  ctx_ddl.add_field_section
    (
      group_name   => 'my_basic_section_group',
      section_name => 'pagedata',
      tag          => 'pagedata'
    );
end;
/

drop index datastores_concat;

select err_text from ctx_user_index_errors;

create index url_uds_concat on url_uds ( concat )
  indextype is ctxsys.context
  parameters ( '
    datastore        my_user_datastore
    lexer            my_basic_lexer
    section group    my_basic_section_group ' );

select err_text from ctx_user_index_errors;

select url from url_uds 
where contains (concat, 'roger within title and aprilia within urldata')>0