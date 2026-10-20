package demo;

import java.sql.Connection;
import java.sql.SQLException;
import java.time.Duration;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import oracle.jdbc.datasource.impl.OracleDataSource;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSourceFactory;

/** Explicit OCI workload identity, with no database password or API-key fallback. */
public final class OciWorkloadPrincipalDemo {
    private OciWorkloadPrincipalDemo() { }

    record Config(String url, String expectedUser, Properties properties) { }

    static Config configure(String principal, Map<String, String> env) {
        String method = switch (principal) {
            case "instance" -> "OCI_INSTANCE_PRINCIPAL";
            case "resource" -> "OCI_RESOURCE_PRINCIPAL";
            default -> throw new IllegalArgumentException("Use instance or resource");
        };
        String url = required(env, "ADB_JDBC_URL");
        Settings.validateUrl(url);
        String expected = required(env, "EXPECTED_DB_USER");
        if (!expected.matches("[A-Z][A-Z0-9_]{0,127}"))
            throw new IllegalArgumentException("EXPECTED_DB_USER must be an uppercase unquoted schema name");
        Properties properties = new Properties();
        properties.setProperty("v$session.program", "devrel-developerhub-java-jdbc-token-auth");
        properties.setProperty("oracle.jdbc.tokenAuthentication", method);
        properties.setProperty("oracle.jdbc.ociCompartment", required(env, "OCI_COMPARTMENT_ID"));
        properties.setProperty("oracle.jdbc.ociDatabase", required(env, "OCI_DATABASE_ID"));
        properties.setProperty("oracle.net.CONNECT_TIMEOUT", "15000");
        properties.setProperty("oracle.jdbc.ReadTimeout", "30000");
        return new Config(url, expected, properties);
    }

    private static String required(Map<String, String> env, String name) {
        String value = env.get(name);
        if (value == null || value.isBlank()) throw new IllegalArgumentException("Set " + name);
        return value;
    }

    public static void main(String[] args) {
        try {
            if (args.length != 2 || !Set.of("check", "jdbc", "ucp").contains(args[1]))
                throw new IllegalArgumentException("Usage: OciWorkloadPrincipalDemo instance|resource check|jdbc|ucp");
            Config config = configure(args[0], System.getenv());
            if (args[1].equals("check")) {
                System.out.println("Configuration valid; no identity, token, or database test performed.");
                return;
            }
            // The runtime supplies instance metadata or resource-principal credentials.
            // Selecting a method does not create that identity on a developer laptop.
            if (args[1].equals("jdbc")) {
                OracleDataSource ds = new OracleDataSource();
                ds.setURL(config.url());
                ds.setConnectionProperties(config.properties());
                try (Connection connection = ds.getConnection()) {
                    verify(connection, config.expectedUser());
                }
            } else {
                var pool = PoolDataSourceFactory.getPoolDataSource();
                String name = "WorkloadPrincipalDemo";
                pool.setConnectionPoolName(name);
                pool.setConnectionFactoryClassName(OracleDataSource.class.getName());
                pool.setURL(config.url());
                pool.setConnectionProperties(config.properties());
                pool.setInitialPoolSize(0);
                pool.setMinPoolSize(0);
                pool.setMaxPoolSize(2);
                pool.setConnectionWaitDuration(Duration.ofSeconds(20));
                pool.setValidateConnectionOnBorrow(true);
                var manager = UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager();
                try (Connection connection = pool.getConnection()) {
                    verify(connection, config.expectedUser());
                } finally {
                    if (java.util.Arrays.asList(manager.getConnectionPoolNames()).contains(name))
                        manager.destroyConnectionPool(name);
                }
            }
        } catch (Exception failure) {
            // Exception payloads can contain endpoints or credentials. Report codes only.
            if (failure instanceof IllegalArgumentException) System.err.println(failure.getMessage());
            else {
                System.err.println("Connection/identity check failed: " + failure.getClass().getSimpleName());
                for (Throwable cause = failure; cause != null; cause = cause.getCause())
                    if (cause instanceof SQLException sql)
                        System.err.println("Oracle error=" + sql.getErrorCode() + "; SQLState=" + sql.getSQLState());
            }
            System.exit(1);
        }
    }

    static void verifyIdentity(String expected, String actual, String authentication) throws SQLException {
        if (!expected.equals(actual) || !"TOKEN_GLOBAL".equals(authentication))
            throw new SQLException("Unexpected database identity or authentication method");
    }

    private static void verify(Connection connection, String expected) throws SQLException {
        try (var statement = connection.prepareStatement("""
                SELECT SYS_CONTEXT('USERENV','SESSION_USER'),
                       SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') FROM dual
                """)) {
            try (var rows = statement.executeQuery()) {
                if (!rows.next()) throw new SQLException("Identity query returned no row");
                verifyIdentity(expected, rows.getString(1), rows.getString(2));
                System.out.println("PASS: expected schema; authentication=TOKEN_GLOBAL; read-only query completed.");
            }
        }
    }
}
