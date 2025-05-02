/*
  Copyright (c) 2025, Oracle and/or its affiliates.

  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

/*
  DESCRIPTION
  This sample shows how to use SSO uging Kerberos on Windows.
  Since WIN2019 allowtgtsessionkey registry key is not available 
  and the only option how to acces Kerberos TGT is via Java's SSPI bridge.
	
  PREREQUISITIES
  - Configure Kerberos authentication for Oracle database as described here:
  https://blog.pythian.com/part-4-implementing-oracle-database-single-sign-on-using-kerberos-active-directory-and-oracle-cmu/
      
  - Create DB user identified extenally as:
  CREATE USER <AD LOGIN> IDENTIFIED EXTERNALLY AS '<AD LOGIN>@<AD REALM>';
  GRANT CONNECT TO <AD LOGIN>;
     
  - Check your Windows has generater Kerb tickets during logon
  klist tgt
  klist
     
  - Connect to database using this program. 
  Java's SSPI bridge(sspi_bridge.dll) should be used to renerate required Kerberos ticket for SSO.

   NOTES
   Use JDK 13 and above on Windows. Check presence of sspi_bridge.dll in JDK intalation.

   MODIFIED    (MM/DD/YY)
   ibre5041    18/04/2025 - Creation
*/

package kerb;

import java.sql.ResultSet;
import java.sql.Statement;

import java.util.Properties;

import org.ietf.jgss.GSSCredential;
import org.ietf.jgss.GSSManager;
import org.ietf.jgss.GSSName;
import org.ietf.jgss.Oid;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleConnectionBuilder;
import oracle.jdbc.pool.OracleDataSource;
import oracle.net.ano.AnoServices;

public class GSSAuthSSPIConnectSample {
  // This should return your AD LOGIN
  String username = System.getProperty("user.name");
  // This should return your AD KERBEROS REALM
  String domain = System.getenv("USERDNSDOMAIN");
  // Your Database JDBC URL here
  String url = "jdbc:oracle:thin:@//dbhost1:1521/DBSERVICE";

  public GSSAuthSSPIConnectSample() {
  }
  
  public void doit() throws Exception
  {
    // Use env variable SSPI_BRIDGE_TRACE=1 in order to trace Java's sspi_bridge.dll plugin
    // set SSPI_BRIDGE_TRACE=1
    
    // Various useful tracing options
    // System.setProperty("oracle.jdbc.Trace", "true");
    // System.setProperty("sun.security.krb5.debug", "true");
    // System.setProperty("sun.security.spnego.debug", "true");
    // System.setProperty("sun.security.jgss.debug", "true");
    // System.setProperty("java.security.debug", "true");
    // System.setProperty("sun.security.nativegss.debug", "true");

    // Activate SSPI bridge, your Kerberos token will be created using Windows SSPI API
    System.setProperty("sun.security.jgss.native", "true");
    // Uncomment this this line for JDK 11, for newer JDK versions this value should be default
    // System.setProperty("sun.security.jgss.lib", "sspi_bridge.dll");

    Oid krb5Oid = new Oid("1.2.840.113554.1.2.2");
    GSSManager manager = GSSManager.getInstance();

    GSSName srcName = manager.createName(username + "@" + domain, GSSName.NT_USER_NAME);
    GSSCredential cred = manager.createCredential(srcName
						  , GSSCredential.DEFAULT_LIFETIME
						  , krb5Oid, GSSCredential.INITIATE_ONLY);

    Properties prop = new Properties();
    prop.setProperty(AnoServices.AUTHENTICATION_PROPERTY_SERVICES, "(" + AnoServices.AUTHENTICATION_KERBEROS5 + ")");
    prop.setProperty(OracleConnection.CONNECTION_PROPERTY_THIN_NET_AUTHENTICATION_SERVICES,"( " + AnoServices.AUTHENTICATION_KERBEROS5 + " )");
    prop.setProperty(OracleConnection.CONNECTION_PROPERTY_THIN_NET_AUTHENTICATION_KRB5_MUTUAL, "true");

    OracleDataSource ods = new OracleDataSource();
    ods.setURL(url);
    ods.setConnectionProperties(prop);
    OracleConnectionBuilder builder = ods.createConnectionBuilder();
    OracleConnection conn = builder.gssCredential(cred).build();
        
    String auth = ((OracleConnection)conn).getAuthenticationAdaptorName();
    System.out.println("Authentication adaptor:"+auth);

    String sql = "select user from dual";
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery(sql);
    while (rs.next())
      System.out.println("whoami: " + rs.getString(1));

    conn.close();
  }

  public static void main(String[] args) {
    GSSAuthSSPIConnectSample test = new GSSAuthSSPIConnectSample();
    try {
      test.doit();
      System.out.println("Done");
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
}
