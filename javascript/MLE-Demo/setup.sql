declare
    l_hostname varchar2(64) := '*.googleapis.com';
    l_port number := 443;
    l_principal varchar2(64);

    procedure add_priv(p_priv varchar2, p_host varchar2, p_port number) is
    begin
        dbms_network_acl_admin.append_host_ace (
            host       => p_host, 
            lower_port => p_port,
            upper_port => p_port,
            ace        => 
                xs$ace_type(privilege_list => xs$name_list(p_priv),
                            principal_name => l_principal,
                            principal_type => xs_acl.ptype_db));
    end;

    procedure add_priv_resolve(p_host varchar2) is
    begin
        dbms_network_acl_admin.append_host_ace (
            host       => p_host,
            ace        => 
                xs$ace_type(privilege_list => xs$name_list('resolve'),
                            principal_name => l_principal,
                            principal_type => xs_acl.ptype_db)); 
    end;
begin
    l_principal := '&please_enter_schema_name';
    add_priv('connect',l_hostname,l_port);
    add_priv_resolve(l_hostname);
    add_priv('http',l_hostname,l_port);
    commit;
end;
/
