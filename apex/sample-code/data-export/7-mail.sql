declare
    l_context       apex_exec.t_context;

    l_column_groups apex_data_export.t_column_groups;
    l_group_emp     pls_integer;
    l_group_dept    pls_integer;
    l_columns       apex_data_export.t_columns;
    l_highlights    apex_data_export.t_highlights;
    l_aggregates    apex_data_export.t_aggregates;
    l_print_config  apex_data_export.t_print_config;
    l_export        apex_data_export.t_export;

    l_mail_id       number;
begin

    apex_session.create_session(
        p_app_id    => 101,
        p_page_id   => 1,
        p_username  => 'DUMMY' );

    l_context := apex_exec.open_query_context(
        p_location          => apex_exec.c_location_local_db,
        p_sql_query         => q'[select e.ename,
       e.job,
       m.ename as manager,
       e.hiredate,
       e.sal,
       d.dname,
       d.loc,
       case e.job
        when 'MANAGER' then 1
        when 'SALESMAN' then 2
        end row_highlight,
       case when e.sal >= 3000 then 3 end col_highlight,
       sum(e.sal) over (partition by e.deptno) dept_sal,
       sum(e.sal) over () total_sal
  from emp e
  join dept d
    on d.deptno = e.deptno
  left join emp m
    on e.mgr = m.empno
 order by e.deptno]' );

    apex_data_export.add_column_group( p_column_groups => l_column_groups, p_idx => l_group_emp, p_name => 'Employee' );
    apex_data_export.add_column_group( p_column_groups => l_column_groups, p_idx => l_group_dept, p_name => 'Department' );

    apex_data_export.add_column( p_columns => l_columns, p_name => 'DNAME', p_heading => 'Department', p_is_column_break => true );
    apex_data_export.add_column( p_columns => l_columns, p_name => 'ENAME', p_heading => 'Employee', p_column_group_idx => l_group_emp);
    apex_data_export.add_column( p_columns => l_columns, p_name => 'JOB', p_heading => 'Job', p_column_group_idx => l_group_emp);
    apex_data_export.add_column( p_columns => l_columns, p_name => 'MANAGER', p_heading => 'Manager', p_column_group_idx => l_group_emp);
    apex_data_export.add_column( p_columns => l_columns, p_name => 'HIREDATE', p_heading => 'Hire date', p_format_mask => 'DD-MM-YYYY', p_column_group_idx => l_group_emp);
    apex_data_export.add_column( p_columns => l_columns, p_name => 'SAL', p_heading => 'Salary', p_format_mask => 'FML999G999G999G999G990D00', p_column_group_idx => l_group_emp);
    apex_data_export.add_column( p_columns => l_columns, p_name => 'LOC', p_heading => 'Location', p_column_group_idx => l_group_dept);

    apex_data_export.add_highlight( p_highlights => l_highlights, p_id => 1, p_value_column => 'ROW_HIGHLIGHT', p_background_color => '#DAFF33' );
    apex_data_export.add_highlight( p_highlights => l_highlights, p_id => 2, p_value_column => 'ROW_HIGHLIGHT', p_background_color => '#9884DD' );
    apex_data_export.add_highlight( p_highlights => l_highlights, p_id => 3, p_value_column => 'COL_HIGHLIGHT', p_background_color => 'red', p_text_color => 'white', p_display_column => 'SAL' );

    apex_data_export.add_aggregate(
        p_aggregates              => l_aggregates,
        p_label                   => 'Sum',
        p_format_mask             => 'FML999G999G999G999G990D00',
        p_display_column          => 'SAL',
        p_value_column            => 'DEPT_SAL',
        p_overall_label           => 'Total sum',
        p_overall_value_column    => 'TOTAL_SAL' );

    l_print_config := apex_data_export.get_print_config(
        p_page_header               => 'Employee overview as of ' || to_char( sysdate, 'DL' ),
        p_page_header_font_size     => 20,
        p_page_header_font_color    => '#BC513E',
        p_border_width              => 0.5 );

    l_export := apex_data_export.export (
        p_context           => l_context,
        p_format            => nvl( :format, apex_data_export.c_format_html ),
        p_columns           => l_columns,
        p_column_groups     => l_column_groups,
        p_highlights        => l_highlights,
        p_aggregates        => l_aggregates,
        p_print_config      => l_print_config,
        p_supplemental_text => 'For demo purposes only' );

    apex_exec.close( l_context );

    l_mail_id := apex_mail.send (
        p_template_static_id => 'EMPLOYEES',
        p_placeholders       => '{ "NAME": ' || apex_json.stringify( :name ) || ' }',
        p_from               => 'menno.hoogendijk@oracle.com',
        p_to                 => :to );

    apex_mail.add_attachment(
        p_mail_id    => l_mail_id,
        p_attachment => l_export.content_blob,
        p_filename   => l_export.file_name,
        p_mime_type  => l_export.mime_type );

    apex_mail.push_queue;

    htp.prn('Email send to ' || :to);
exception
    when others then
        apex_exec.close( l_context );
        raise;
end;
