DECLARE
  l_acl_name VARCHAR2(100);
  CURSOR c_network_acls IS
    SELECT acl FROM dba_network_acls WHERE host = '*.googleapis.com';
BEGIN
  -- Drop the INVENTORY table
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE INVENTORY';
    DBMS_OUTPUT.PUT_LINE('Table INVENTORY dropped successfully.');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('Table INVENTORY does not exist.');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
  END;

  -- Find the ACL name for host '*.googleapis.com'
  OPEN c_network_acls;
  FETCH c_network_acls INTO l_acl_name;

  -- Process each row returned by the cursor
  WHILE c_network_acls%FOUND LOOP
    -- Unassign the ACL
    DBMS_NETWORK_ACL_ADMIN.UNASSIGN_ACL(acl => l_acl_name);
    FETCH c_network_acls INTO l_acl_name;
  END LOOP;

  CLOSE c_network_acls;
  
  COMMIT;
END;
/
