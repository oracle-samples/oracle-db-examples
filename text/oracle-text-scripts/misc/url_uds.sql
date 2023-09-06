connect roger/rogerpasswd@connectstring

drop table url_uds;
create table url_uds (pk number primary key, title varchar2(80), 
                      url varchar2(2000), concat varchar2(1));

insert into url_uds values (1, 'Yahoo! main page', 'http://www.yahoo.com', 'x');
insert into url_uds values (2, 'Google search engine', 'http://www.google.com', 'x');
insert into url_uds values (3, 'Roger Ford''s racing page', 'http://www.serve.com/magsport/', 'x');

commit;

connect ctxsys/ctxsys@connectstring

create or replace procedure url_uds_proc
/*
  Must be in ctxsys schema.
  In a full-scale example, this would be a wrapper
  for a proc in the user schema.
*/
  (
    rid  in              rowid,
    tlob in out NOCOPY   clob    /* NOCOPY instructs Oracle to pass
                                    this argument as fast as possible */
  )
is
  v_title                        varchar2(2000);
  v_url				 varchar2(2000);
  v_url_data                     varchar2(32767);
  v_doc                     clob;
  v_doc_name            constant varchar2(20) := 'pagedata';
  v_doc_start_tag       constant varchar2(20) := '<'  || v_doc_name || '>';
  v_doc_end_tag         constant varchar2(20) := '</' || v_doc_name || '>';
  v_title_name          constant varchar2(20) := 'pagetitle';
  v_title_start_tag     constant varchar2(20) := '<'  || v_title_name   || '>';
  v_title_end_tag       constant varchar2(20) := '</' || v_title_name   || '>';
  v_buffer                       varchar2(4000);
  v_length                       integer;
begin

  select title, url
    into v_title, v_url
    from roger.url_uds where rowid = rid;

  v_url_data := utl_http.request( url => v_url, proxy => null);

  v_buffer := v_title_start_tag ||
              v_title           ||
              v_title_end_tag;
  v_length := length ( v_buffer );

  Dbms_Lob.Trim
    (
      lob_loc        => tlob,
      newlen         => 0
    );

  Dbms_Lob.Write
    (
      lob_loc        => tlob,
      amount         => v_length,
      offset         => 1,
      buffer         => v_buffer
    );

  Dbms_Lob.WriteAppend (tlob, length(v_doc_start_tag), v_doc_start_tag);

  Dbms_Lob.WriteAppend (tlob, length(v_url_data), v_url_data);

  Dbms_Lob.WriteAppend (tlob, length(v_doc_end_tag),   v_doc_end_tag );


end url_uds_proc;
/
Show Errors
--list

grant execute on url_uds_proc to public;

connect roger/rogerpasswd@connectstring
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
       group_type => 'html_section_group'
    );
  ctx_ddl.add_field_section
    (
      group_name   => 'my_basic_section_group',
      section_name => 'pagetitle',
      tag          => 'pagetitle',
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
where contains (concat, '(roger within pagetitle) and (aprilia within pagedata)')>0;

