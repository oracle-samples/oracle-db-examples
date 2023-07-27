/*Copyright 2023 Oracle and/or its affiliates.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

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
