/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/**
 * DESCRIPTION
 *
 * This class demonstrates how to specify a URL to the Oracle JDBC Driver.
 * <br>
 * The demo can be configured to use the following forms of URLs:
 * <ol>
 *   <li>Thin-Style</li>
 *   <li>Oracle Net Connect Descriptor</li>
 *   <li>TNS Alias</li>
 * </ol>
 *
 * <h3>Thin-Style URL</h3>
 * Thin-style is the simplest form of URL. It consists of a host, port, and a
 * service name or system identifier (SID). To run the demo using a thin-style
 * URL, provide command line arguments in either of the following forms:
 * <br>
 * <code>-t {host} {port} {sid}</code>
 * <br>
 * <code>-t {host} {port} /{service_name}</code>
 * <br>
 * Note the '/' character is used to differentiate between an SID and service name.
 *
 * <h3>Connect Descriptor URL</h3>
 * Connect descriptors offer a syntax for advanced configuration of the
 * network connection. To learn about the syntax, see the Oracle Net Database
 * Net Services Guide linked to below. This demo will use a minimal
 * configuration consisting of a host, port, and service name or SID. To run
 * the demo using a connect descriptor URL, provide command line arguments in
 * either of the following forms:
 * <br>
 * <code>-c {host} {port} {sid}</code>
 * <br>
 * <code>-c {host} {port} /{service_name}</code>
 * <br>
 * Note the '/' character is used to differentiate between an SID and service name.
 *
 * <h3>TNS Alias URL</h3>
 * A TNS alias is a reference to an connect descriptor defined in a
 * tnsnames.ora file. To learn more about tnsnames.ora, see the Oracle
 * Database Net Services Reference linked to below. To run the demo using a
 * TNS alias URL, provide command line arguments in either of the following
 * forms:
 * <br>
 * <code>-a {alias} {tns_names_dir}</code>
 * <br>
 * Where tns_names_dir is the directory which holds tnsnames.ora.
 *
 * <h3>Further Reading</h3>
 * <ul>
 * <li>
 * To learn more about URL's and the Oracle JDBC Driver, have a look at our
 * Developer's Guide.
 * <a target="_blank" href="http://www.oracle.com/technetwork/database/application-development/jdbc/learnmore/index.html">
 * The latest version can be found here.
 * </a> URLs are discussed in <i>Chapter 8 Data Sources and URLs</i>.
 * </li>
 * <li>
 * To learn more about Oracle Net concepts (such as the difference between a
 * service and SID, or the full syntax of a connect descriptor), see
 * <i>Chapter 2 Identifying and Accessing the Database</i> in the Oracle
 * Database Net Services Guide.
 * <a target="_blank" href="https://docs.oracle.com/en/database/oracle/oracle-database/18/netag/identifying-and-accessing-database.html#GUID-5BC573CE-BA12-4251-A987-429095385EC2">
 * The latest version is 18.1, which can be found here
 * </a>
 * </li>
 * <li>
 * To learn more about TNS names aliases and the syntax of tnsnames.ora, see
 * <i>Chapter 6 Local Naming Parameters in the tnsnames.ora File</i> in the
 * Oracle Database Net Services Reference.
 * <a target="_blank" href="https://docs.oracle.com/en/database/oracle/oracle-database/18/netrf/local-naming-parameters-in-tnsnames-ora-file.html#GUID-A3F9D023-9CC4-445D-8921-6E40BD900EAD">
 * The latest version is 18.1, which can be found here.
 * </a>
 * </li>
 * </ul>
 */

import java.io.Console;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Objects;
import java.util.Properties;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jdbc.OracleConnection;

public class JDBCUrlSample {

  // Default credentials to use if a console is not available. If you are
  // running this demo in an IDE like Eclipse, you may need to define these
  // values.
  private static final String DEFAULT_USER = "";
  private static final String DEFAULT_PASSWORD = "";

  /** The URL this demo will use */
  private final String url;

  /** Connection properties this demo will use. */
  private final Properties connectionProperties;

  private JDBCUrlSample(String url){
    this(url, new Properties());
  }

  private JDBCUrlSample(String url, Properties connectionProperties) {
    this.url = url;
    this.connectionProperties = connectionProperties;
  }

  /**
   * Returns a new demo object initialized with a thin-style URL using a
   * database service name.
   * <p style="white-space:pre;">
   * The URL syntax is:
   * jdbc:oracle:thin:@{host_name}:{port_number}/{service_name}
   * </p>
   * @param host The hostname of an Oracle Database.
   * @param port The port number of an Oracle Database.
   * @param service The service name of an Oracle Database.
   * @return A newly instantiated demo object.
   */
  public static JDBCUrlSample newThinStyleServiceNameDemo(String host,
          int port, String service) {
    Objects.requireNonNull(host, "Host cannot be null");
    Objects.requireNonNull(service, "Service name cannot be null");

    String thinStyleURL =
      "jdbc:oracle:thin:@" + host + ":" + port + "/" + service;
    return new JDBCUrlSample(thinStyleURL);
  }

  /**
   * Returns a new demo object initialized with a thin-style URL using
   * a database SID.
   * <p style="white-space:pre;">
   * The URL syntax is:
   * jdbc:oracle:thin:@{host_name}:{port_number}:{sid}
   * </p>
   * @param host The hostname of an Oracle Database.
   * @param port The port number of an Oracle Database.
   * @param sid The system identifier of an Oracle Database.
   * @return A newly instantiated demo object.
   */
  public static JDBCUrlSample newThinStyleSIDDemo(String host, int port,
                                                 String sid) {
    Objects.requireNonNull(host, "Host cannot be null");
    Objects.requireNonNull(sid, "SID cannot be null");

    String thinStyleURL =
            "jdbc:oracle:thin:@" + host + ":" + port + ":" + sid;
    return new JDBCUrlSample(thinStyleURL);
  }

  /**
   * Returns a new demo object initialized with a connect descriptor URL using
   * a service name.
   * <p style="white-space:pre;">
   * The URL syntax is:
   * jdbc:oracle:thin:@(DESCRIPTION=
   *                     (ADDRESS=(PROTOCOL=tcp)(HOST={host_name})(PORT={port}))
   *                     (CONNECT_DATA=(SERVICE_NAME={service_name})))
   * </p>
   * @param host The hostname of an Oracle Database.
   * @param port The port number of an Oracle Database.
   * @param service The service name of an Oracle Database.
   * @return A newly instantiated demo object.
   */
  public static JDBCUrlSample newConnectDescriptorServiceNameDemo(String host,
          int port, String service) {
    Objects.requireNonNull(host, "Host cannot be null");
    Objects.requireNonNull(service, "Service name cannot be null");

    String connectDescriptorURL =
      "jdbc:oracle:thin:@(DESCRIPTION="
      + "(ADDRESS=(PROTOCOL=tcp)(HOST=" + host + ")(PORT=" + port + "))"
      + "(CONNECT_DATA=(SERVICE_NAME=" + service + ")))";

    return new JDBCUrlSample(connectDescriptorURL);
  }

  /**
   * Returns a new demo object initialized with a connect descriptor URL using
   * a database SID.
   * <p style="white-space:pre;">
   * The URL syntax is:
   * jdbc:oracle:thin:@(DESCRIPTION=
   *                     (ADDRESS=(PROTOCOL=tcp)(HOST={host_name})(PORT={port}))
   *                     (CONNECT_DATA=(SID={sid})))
   * </p>
   * @param host The hostname of an Oracle Database.
   * @param port The port number of an Oracle Database.
   * @param sid The system identifier of an Oracle Database.
   * @return A newly instantiated demo object.
   */
  public static JDBCUrlSample newConnectDescriptorSIDDemo(String host, int port,
                                                        String sid) {
    Objects.requireNonNull(host, "Host cannot be null");
    Objects.requireNonNull(sid, "SID cannot be null");

    String connectDescriptorURL =
      "jdbc:oracle:thin:@(DESCRIPTION="
      + "(ADDRESS=(PROTOCOL=tcp)(HOST=" + host + ")(PORT=" + port + "))"
      + "(CONNECT_DATA=(SID=" + sid + ")))";

    return new JDBCUrlSample(connectDescriptorURL);
  }

  /**
   * Returns a new demo object initialized with a TNS Alias URL.
   * The syntax is:
   * <p style="white-space:pre;">
   * jdbc:oracle:thin:@{tns_alias}
   * </p>
   * @param alias A tnsnames.ora alias.
   * @param tnsAdmin The directory of a tnsnames.ora file.
   * @return A newly instantiated demo object.
   */
  public static JDBCUrlSample newTNSAliasDemo(String alias, String tnsAdmin) {
    Objects.requireNonNull(alias, "Alias cannot be null");
    Objects.requireNonNull(tnsAdmin, "TNS Admin cannot be null");

    String tnsAliasURL = "jdbc:oracle:thin:@" + alias;

    // The directory of tnsnames.ora is defined as a connection property.
    Properties connectionProperties = new Properties();
    connectionProperties.setProperty(
            OracleConnection.CONNECTION_PROPERTY_TNS_ADMIN, tnsAdmin);

    return new JDBCUrlSample(tnsAliasURL, connectionProperties);
  }

  /**
   * Use this demo's URL to establish a connection.
   */
  public void connectWithURL() {
    try {

      // oracle.jdbc.pool.OracleDataSource is a factory for Connection
      // objects.
      OracleDataSource dataSource = new OracleDataSource();

      // The data source is configured with database user and password.
      setCredentials(dataSource);

      // The data source is configured with connection properties.
      dataSource.setConnectionProperties(connectionProperties);

      // The data source is configured with a database URL.
      dataSource.setURL(url);

      // The data source is used to create a Connection object.
      System.out.println("\nConnecting to: " + url);
      Connection connection = dataSource.getConnection();
      System.out.println("Connection Established!");

      // Close the connection when its no longer in use. This will free up
      // resources in the Java client and the database host.
      connection.close();
    }
    catch (SQLException sqlE) {
      // The getConnection() call throws a SQLException if a connection could
      // not be established.
      displayConnectionError(sqlE);
    }
  }

  private void setCredentials(OracleDataSource dataSource) {
    String user;
    char[] password;
    Console console = System.console();

    if(console == null) {
      System.out.println(
              "\nNo console available. Using default user and password.");
      user = DEFAULT_USER;
      password = DEFAULT_PASSWORD.toCharArray();
    }
    else {
      user = console.readLine("\nUser: ");
      password = console.readPassword(user + "'s password: ");
    }

    dataSource.setUser(user);
    dataSource.setPassword(new String(password));
    Arrays.fill(password, ' ');
  }

  private void displayConnectionError(SQLException sqlE) {
    System.out.println(
            "Connection establishment failed with the following error:");

    Throwable cause = sqlE;
    do {
      System.out.println(cause.getMessage());
      cause = cause.getCause();
    } while(cause != null);
  }

  // All code beyond this point is related to command line argument parsing.
  private static final String THIN_STYLE_OPTION = "-t";
  private static final String DESCRIPTOR_OPTION = "-c";
  private static final String TNS_ALIAS_OPTION = "-a";
  private static final String USAGE_MESSAGE =
    "Please provide command line arguments in one of the following forms:"
    + "\n\nThin-Style URL:\n\t"
    + THIN_STYLE_OPTION + " {host} {port} {sid}\n\t"
    + THIN_STYLE_OPTION + " {host} {port} /{service_name}"
    + "\n\nOracle Net Connect Descriptor:\n\t"
    + DESCRIPTOR_OPTION + " {host} {port} {sid}\n\t"
    + DESCRIPTOR_OPTION + " {host} {port} /{service_name}"
    + "\n\nTNS Names Alias:\n\t"
    + TNS_ALIAS_OPTION + " {alias} {tnsnames_directory}";

  private static int ARG_POSITION_HOST = 1;
  private static int ARG_POSITION_PORT = 2;
  private static int ARG_POSITION_SERVICE = 3;
  private static int THIN_STYLE_ARG_COUNT = 4;
  private static int DESCRIPTOR_ARG_COUNT = 4;

  private static int ARG_POSITION_ALIAS = 1;
  private static int ARG_POSITION_TNS_ADMIN = 2;
  private static int TNS_ALIAS_ARG_COUNT = 3;

  public static void main(String[] args) {

    // Read the URL type argument and initialize a demo for it.
    JDBCUrlSample demo = null;
    String typeOption = args.length > 0 ? args[0] : "";
    switch(typeOption) {

      case THIN_STYLE_OPTION:
        if(args.length == THIN_STYLE_ARG_COUNT) {
          String host = args[ARG_POSITION_HOST];
          int port = Integer.valueOf(args[ARG_POSITION_PORT]);
          String service = args[ARG_POSITION_SERVICE];
          demo = service.startsWith("/")
                 ? newThinStyleServiceNameDemo(host, port,
                                               service.substring(1))
                 : newThinStyleSIDDemo(host, port, service);

        }
        break;

      case DESCRIPTOR_OPTION:
        if(args.length == DESCRIPTOR_ARG_COUNT) {
          String host = args[ARG_POSITION_HOST];
          int port = Integer.valueOf(args[ARG_POSITION_PORT]);
          String service = args[ARG_POSITION_SERVICE];
          demo = service.startsWith("/")
                 ? newConnectDescriptorServiceNameDemo(host, port,
                                                       service.substring(1))
                 : newConnectDescriptorSIDDemo(host, port, service);
        }
        break;

      case TNS_ALIAS_OPTION:
        if(args.length == TNS_ALIAS_ARG_COUNT) {
          String alias = args[ARG_POSITION_ALIAS];
          String tnsAdmin = args[ARG_POSITION_TNS_ADMIN];
          demo = newTNSAliasDemo(alias, tnsAdmin);
        }
        break;

      default:
        demo = null;
    }

    if(demo == null) {
      System.out.println(USAGE_MESSAGE);
    }
    else {
      demo.connectWithURL();
    }
  }
}
