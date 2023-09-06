set define off

begin
  Ctx_Ddl.Drop_Preference ( 'my_basic_lexer' );
end;
/

begin
  Ctx_Ddl.Create_Preference
    (
      preference_name => 'my_basic_lexer',
      object_name     => 'basic_lexer'
    );
  Ctx_Ddl.Set_Attribute
    (
      preference_name => 'my_basic_lexer',
      attribute_name  => 'printjoins',
      attribute_value => '&'
    );
end;
/

rem as you are failry new to this area I have included an example for DBA's to
rem control the storage.

begin
  Ctx_Ddl.Drop_Preference ( 'my_basic_storage' );
end;
/

begin
  Ctx_Ddl.Create_Preference('my_basic_storage', 'basic_storage');
  Ctx_Ddl.Set_Attribute
    (      preference_name => 'my_basic_storage',
      attribute_name  => 'i_table_clause',
      attribute_value => 'tablespace users storage (initial 1K)'
    );
  Ctx_Ddl.Set_Attribute ( 'my_basic_storage', 'k_table_clause',
                          'tablespace users storage (initial 1K)');
  Ctx_Ddl.Set_Attribute ( 'my_basic_storage', 'r_table_clause',
                          'tablespace users storage (initial 1K)');
  Ctx_Ddl.Set_Attribute ( 'my_basic_storage', 'n_table_clause',
                          'tablespace users storage (initial 1K)');
  Ctx_Ddl.Set_Attribute ( 'my_basic_storage', 'i_table_clause',
                          'tablespace users storage (initial 1K)');
end;
/

Rem create and populate a test table to try this out

create table attributevalue 
  (pk number primary key, stringvalue varchar2(4000));

insert into attributevalue values (1, 'Black & Decker Powerdrills');
insert into attributevalue values (2, 'Fish&Chips');
commit;

create index stringvalue_text on attributevalue ( stringvalue )
  indextype is ctxsys.context
  parameters ( 'lexer my_basic_lexer storage my_basic_storage'
);

Rem now try a query or two

column stringvalue format a50
set echo on

select pk, stringvalue from attributevalue 
where contains (stringvalue, '\&') > 0;

select pk, stringvalue from attributevalue 
where contains (stringvalue, 'Fish\&Chips') > 0;

Rem this one is NOT recommended as it will disable the index
Rem on the token table which stores the indexed words

select pk, stringvalue from attributevalue 
where contains (stringvalue, '%\&%') > 0;


