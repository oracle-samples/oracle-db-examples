column idx_name format a25
  column idx_table format a25
  column idx_text_name format a25
  select idx_name, idx_table, idx_text_name
    from ctx_user_indexes;


Set ServerOutput On Buffer=1000000
create or replace procedure Index_Values
  (
    p_index_name in varchar2
  )
is
  v_attributes integer;
begin
  Dbms_Output.Enable ( buffer_size => 1000000 );
  for i in
    (
      select ixo_object
        from ctx_user_index_objects
        where ixo_index_name = upper ( p_index_name )
        order by ixo_class
    )
  loop
    Dbms_Output.Put_Line ( chr(10) || rpad ( '-', 30, '-' ) || chr(10) ||
                           lower ( i.ixo_object ) );
    v_attributes := 0;
    for j in
      (
        select ixv_attribute, ixv_value
          from ctx_user_index_values
          where ixv_index_name = upper ( p_index_name )
          and ixv_object = i.ixo_object
          order by ixv_attribute, ixv_value
      )
    loop
      v_attributes := v_attributes + 1;
      Dbms_Output.Put_Line ( '. ' || 
                             rpad ( lower ( j.ixv_attribute ), 20, ' ' ) ||
                             j.ixv_value );
    end loop;
    if v_attributes < 1
    then
      Dbms_Output.Put_Line ( '. [no attributes]' );
    end if;
  end loop;
  Dbms_Output.Put_Line ( chr(10) || rpad ( '-', 30, '-' ) );
end Index_Values;
/

