/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.*/
/*
   DESCRIPTION
   This code example shows how to use JDBC and UCP's programmatic APIs for
   database authentication, using a token issued by the Oracle Cloud
   Infrastructure (OCI) Identity Service.

   To run this example, Oracle Database must be configured for IAM
   authentication, as described in the Security Guide:
   https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/authenticating-and-authorizing-iam-users-oracle-autonomous-databases.html

   To run this example, the OCI SDK for Java must be configured with a
   configuration profile of an IAM user that is mapped to a database user.
   The OCI Developer Guide describes how to setup and configure the SDK:
   https://docs.oracle.com/en-us/iaas/Content/API/Concepts/devguidesetupprereq.htm

   To run this example, use JDK 11 or newer, and have the classpath include 
   the latest builds of Oracle JDBC, Oracle UCP, Oracle PKI, and the OCI SDK 
   for Java. These artifacts can be obtained from Maven Central by declaring
   these dependencies:
    <dependency>
      <groupId>com.oracle.database.jdbc</groupId>
      <artifactId>ojdbc11-production</artifactId>
      <version>21.4.0.0.1</version>
      <type>pom</type>
    </dependency>
    <dependency>
      <groupId>com.oracle.oci.sdk</groupId>
      <artifactId>oci-java-sdk-identitydataplane</artifactId>
      <version>2.12.0</version>
    </dependency>

   To run this example, set the values of static final fields declared in
   this class:
   DATABASE_URL = URL of an Autonomous Database that JDBC connects to
   OCI_PROFILE = A profile from $HOME/.oci/config of an IAM user that is mapped
     to an Autonomous Database user 

   NOTES
    Use JDK 11 or above
   MODIFIED          (MM/DD/YY)
    Michael-A-McMahon 12/07/21 - Creation
 */

import com.oracle.bmc.auth.AuthenticationDetailsProvider;
import com.oracle.bmc.auth.ConfigFileAuthenticationDetailsProvider;
import com.oracle.bmc.identitydataplane.DataplaneClient;
import com.oracle.bmc.identitydataplane.model.GenerateScopedAccessTokenDetails;
import com.oracle.bmc.identitydataplane.requests.GenerateScopedAccessTokenRequest;
import oracle.jdbc.AccessToken;
import oracle.jdbc.OracleConnectionBuilder;
import oracle.jdbc.datasource.OracleDataSource;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.io.IOException;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;
import java.security.PublicKey;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Base64;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Supplier;

import static java.util.concurrent.TimeUnit.SECONDS;

/**
 * The following is a summary of methods that can be found in this class,
 * with a brief description of what task each method performs:
 *
 * requestToken(PublicKey) shows how to request a token from OCI.
 *
 * createAccessToken() shows how to create an instance of
 * oracle.jdbc.AccessToken using the token requested from OCI.
 *
 * connectJdbc() shows how to create a single JDBC connection using an
 * AccessToken.
 *
 * connectJdbcDataSource() shows how to create multiple JDBC connections
 * using a Supplier that outputs a cached AccessToken.
 *
 * connectUcpDataSource() shows how to create a pool of JDBC connections
 * using a Supplier that outputs a cached AccessToken.
 */
public class JdbcTokenAuthentication {

  /**
   * An Oracle Cloud Infrastructure (OCI) configuration profile name. Profiles
   * are typically defined in $HOME/.oci/config. An access token is requested
   * for the user identified by this profile, and access is requested for all
   * databases within that user's tenancy.
   */
  private static final String OCI_PROFILE =
    /*TODO: Set this to your profile name*/ "DEFAULT";

  /**
   * The URL that JDBC connects with. The default value is using an
   * alias from $TNS_ADMIN/tnsnames.ora
   */
  private static final String DATABASE_URL =
    /*TODO: Set this to your database url*/ "jdbc:oracle:thin:@your_db_name_tp?TNS_ADMIN=/path/to/your/wallet";

  // Print the configured values in this static block
  static {
    System.out.println("DATABASE_URL is set to: " + DATABASE_URL);
    System.out.println("OCI_PROFILE is set to: " + OCI_PROFILE);
  }

  /**
   * This main method executes example code to connect with both JDBC and UCP
   */
  public static void main(String[] args) {
    connectJdbc();
    connectJdbcDataSource();
    connectUcpDataSource();
  }

  /**
   * Creates an {@link AccessToken} that JDBC or UCP can use to authenticate
   * with Oracle Database. The token is requested from the OCI Identity Service.
   * @return An AccessToken from OCI
   */
  private static AccessToken createAccessToken() {

    // Generate a public/private key pair. This is used to protect the token
    // from replay attacks. A client must prove possession of the private
    // key in order to access the database using the token.
    final KeyPair keyPair;
    try {
      keyPair = KeyPairGenerator.getInstance("RSA").generateKeyPair();
    }
    catch (NoSuchAlgorithmException noSuchAlgorithmException) {
      // Not recovering if an RSA KeyPairGenerator is not installed
      throw new RuntimeException(noSuchAlgorithmException);
    }

    // Request an access token from the OCI Identity Service. The token
    // will identify the public key that is paired to the private key
    String token = requestToken(keyPair.getPublic());

    // Create an AccessToken object with the JWT string and the private key
    return AccessToken.createJsonWebToken(
      token.toCharArray(), keyPair.getPrivate());
  }

  /**
   * Requests an access token from the OCI Identity service. The token will
   * identify a {@code publicKey} that is paired to a private key. Possession of
   * the private key must be proven in order to access the database using the
   * token.
   * @param publicKey Public key identified by the token
   * @return Base 64 encoding of a JWT access token
   */
  private static String requestToken(PublicKey publicKey) {
  
    final AbstractAuthenticationDetailsProvider authentication;
    
    // Instance principal and resource principal authentication are also supported, and 
    // can be used as shown below. 
    // authentication = new InstancePrincipalAuthenticationDetailsProvider.builder().build();
    // authentication = new ResourcePrincipalAuthenticationDetailsProvider.builder().build();
     
    try {
      // In this code sample, authentication is shown using a config file. 
      // Read the configuration identified by the OCI_PROFILE
       authentication = new ConfigFileAuthenticationDetailsProvider(OCI_PROFILE);
    }
    catch (IOException ioException) {
      // Not recovering if the profile can not be read
      throw new RuntimeException(ioException);
    }

    // Request the token with the public key encoded as base 64 text
    String base64Key =
      Base64.getEncoder()
        .encodeToString(publicKey.getEncoded());

    // This scope uses the * character to identify all databases in the cloud
    // tenancy of the authenticated user. The * could be replaced with the OCID
    // of a compartment, or of a particular database within a compartment
    String scope = "urn:oracle:db::id::*";

    // Create a GenerateScopedAccessTokenDetails object with the public key
    // and the scope
    GenerateScopedAccessTokenDetails tokenDetails =
      GenerateScopedAccessTokenDetails.builder()
        .publicKey(base64Key)
        .scope(scope)
        .build();

    // Request an access token using a DataplaneClient
    try (DataplaneClient client = new DataplaneClient(authentication)) {
      return client.generateScopedAccessToken(
        GenerateScopedAccessTokenRequest.builder()
          .generateScopedAccessTokenDetails(tokenDetails)
          .build())
        .getSecurityToken()
        .getToken();
    }
  }

  /**
   * Creates a single connection using Oracle JDBC. A call to
   * {@link oracle.jdbc.OracleConnectionBuilder#accessToken(AccessToken)}
   * configures JDBC to authenticate with a token requested from the OCI
   * Identity Service.
   */
  private static void connectJdbc() {
    try {
      // Create a single AccessToken
      AccessToken accessToken = createAccessToken();

      // Configure an OracleConnectionBuilder to authenticate with the
      // AccessToken
      OracleDataSource dataSource = new oracle.jdbc.pool.OracleDataSource();
      dataSource.setURL(DATABASE_URL);
      OracleConnectionBuilder connectionBuilder =
        dataSource.createConnectionBuilder()
          .accessToken(accessToken);

      // Connect and print the database user name
      try (Connection connection = connectionBuilder.build()) {
        System.out.println(
          "Authenticated with JDBC as: " + queryUser(connection));
      }
    }
    catch (SQLException sqlException) {
      // Not recovering if the connection fails
      throw new RuntimeException(sqlException);
    }
  }

  /**
   * Creates multiple connections with Oracle JDBC. A call
   * to {@link OracleDataSource#setTokenSupplier(Supplier)} configures JDBC to
   * authenticate with tokens output by the {@link Supplier}. The
   * {@code Supplier} requests tokens from the OCI Identity Service.
   */
  private static void connectJdbcDataSource() {
    try {

      // Define a Supplier that outputs a cached AccessToken. Caching the
      // token will minimize the number of OCI Identity Service requests. New
      // tokens will only be requested after a previously cached token has
      // expired.
      Supplier<? extends AccessToken> tokenCache =
        AccessToken.createJsonWebTokenCache(() -> createAccessToken());

      // Configure an OracleConnectionBuilder to authenticate with the
      // AccessToken
      OracleDataSource dataSource = new oracle.jdbc.pool.OracleDataSource();
      dataSource.setURL(DATABASE_URL);
      dataSource.setTokenSupplier(tokenCache);

      // Create multiple connections and print the database user name
      for (int i = 0; i < 3; i++) {
        try (Connection connection = dataSource.getConnection()) {
          System.out.println(
            "Authenticated with JDBC as: " + queryUser(connection));
        }
      }
    }
    catch (SQLException sqlException) {
      // Not recovering if the connection fails
      throw new RuntimeException(sqlException);
    }
  }

  /**
   * Creates multiple connections with Universal Connection Pool (UCP). A call
   * to {@link PoolDataSource#setTokenSupplier(Supplier)} configures UCP to
   * authenticate with tokens output by the {@link Supplier}. The
   * {@code Supplier} requests tokens from the OCI Identity Service.
   */
  private static void connectUcpDataSource() {

    // Define a Supplier that outputs a cached AccessToken. Caching the
    // token will minimize the number of OCI Identity Service requests. New
    // tokens will only be requested after a previously cached token has
    // expired.
    Supplier<? extends AccessToken> tokenCache =
      AccessToken.createJsonWebTokenCache(() -> createAccessToken());

    // Configure UCP to use the cached token supplier when creating
    // Oracle JDBC connections
    final PoolDataSource poolDataSource;
    try {
      poolDataSource = PoolDataSourceFactory.getPoolDataSource();
      poolDataSource.setConnectionFactoryClassName(
        oracle.jdbc.pool.OracleDataSource.class.getName());
      poolDataSource.setURL(DATABASE_URL);
      poolDataSource.setMaxPoolSize(2);
      poolDataSource.setTokenSupplier(tokenCache);
    }
    catch (SQLException sqlException) {
      // Not recovering if UCP configuration fails
      throw new RuntimeException(sqlException);
    }

    // Execute multiple threads that share the pool of connections
    ExecutorService executorService =
      Executors.newFixedThreadPool(poolDataSource.getMaxPoolSize());
    try {
      for (int i = 0; i < poolDataSource.getMaxPoolSize() * 2; i++) {
        executorService.execute(() -> {
          try (Connection connection = poolDataSource.getConnection()) {
            System.out.println(
              "Authenticated with UCP as: " + queryUser(connection));
          }
          catch (SQLException sqlException) {
            sqlException.printStackTrace();
          }
        });
      }
    }
    finally {
      executorService.shutdown();
      try {
        executorService.awaitTermination(60, SECONDS);
      }
      catch (InterruptedException interruptedException) {
        // Print the error if interrupted
        interruptedException.printStackTrace();
      }
    }
  }

  /**
   * Queries the database to return the user that a {@code connection} has
   * authenticated as.
   * @param connection Connection to a database
   * @return Database user of the connection
   * @throws SQLException If the database query fails
   */
  private static String queryUser(Connection connection) throws SQLException {
    try (Statement statement = connection.createStatement()) {
      ResultSet resultSet =
        statement.executeQuery("SELECT USER FROM sys.dual");
      resultSet.next();
      return resultSet.getString(1);
    }
  }
}
