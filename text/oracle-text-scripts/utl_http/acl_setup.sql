-- this needs to be run as SYS

-- drop if it already exists

BEGIN
  dbms_network_acl_admin.drop_acl( acl => 'www.xml' );
END;
/

BEGIN
  DBMS_NETWORK_ACL_ADMIN.CREATE_ACL(acl         => 'www.xml',
                                    description => 'WWW ACL',
                                    principal   => 'DIF',
                                    is_grant    => true,
                                    privilege   => 'connect');
 
  DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(acl       => 'www.xml',
                                       principal => 'DIF',
                                       is_grant  => true,
                                       privilege => 'resolve');
 
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl  => 'www.xml',
                                    host => 'slc07dif.us.oracle.com',
                                    lower_port => 8080,
                                    upper_port => 8080);
END;
/
COMMIT;

-- repeat this for each host you want to authorize

BEGIN
  DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL(acl  => 'www.xml',
                                    host => '192.168.1.1',
                                    lower_port => 8080,
                                    upper_port => 8080);
END;
/

