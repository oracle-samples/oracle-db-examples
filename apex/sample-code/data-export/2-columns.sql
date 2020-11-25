declare
    l_context       apex_exec.t_context;

    l_columns       apex_data_export.t_columns;
    l_export        apex_data_export.t_export;
begin

    apex_session.create_session(
        p_app_id    => 101,
        p_page_id   => 1,
        p_username  => 'DUMMY' );

    l_context := apex_exec.open_query_context(
        p_location    => apex_exec.c_location_local_db,
        p_sql_query   => q'[select e.ename,
       e.job,
       m.ename as manager,
       e.hiredate,
       e.sal,
       d.dname,
       d.loc
  from emp e
  join dept d
    on d.deptno = e.deptno
  left join emp m
    on e.mgr = m.empno
 order by e.deptno]' );

    -- Todo: Add column groups

    apex_data_export.add_column( p_columns => l_columns, p_name => 'DNAME', p_heading => 'Department', p_is_column_break => true );
    apex_data_export.add_column( p_columns => l_columns, p_name => 'ENAME', p_heading => 'Employee' );
    apex_data_export.add_column( p_columns => l_columns, p_name => 'JOB');
    apex_data_export.add_column( p_columns => l_columns, p_name => 'MANAGER');
    apex_data_export.add_column( p_columns => l_columns, p_name => 'HIREDATE', p_format_mask => 'DD-MM-YYYY');
    apex_data_export.add_column( p_columns => l_columns, p_name => 'SAL');
    apex_data_export.add_column( p_columns => l_columns, p_name => 'LOC');

    l_export := apex_data_export.export (
        p_context       => l_context,
        p_format        => nvl( :format, apex_data_export.c_format_html ),
        p_columns       => l_columns );

    apex_exec.close( l_context );

    apex_data_export.download( 
        p_export                => l_export,
        p_stop_apex_engine      => false,
        p_content_disposition   => apex_data_export.c_inline );

exception
    when others then
        apex_exec.close( l_context );
        raise;
end;
