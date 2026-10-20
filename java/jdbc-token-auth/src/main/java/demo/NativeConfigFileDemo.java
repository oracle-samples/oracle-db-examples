package demo;

import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

/** Delegate JDBC property-file loading and substitution to the driver. */
public final class NativeConfigFileDemo {
    static OracleDataSource dataSource(String url, Path file) throws SQLException {
        Settings.validateUrl(url);
        if (!Files.isRegularFile(file) || !Files.isReadable(file))
            throw new IllegalArgumentException("Supply a readable, trusted JDBC properties file");
        OracleDataSource ds = new OracleDataSource();
        ds.setURL(url);
        ds.setConnectionProperty(OracleConnection.CONNECTION_PROPERTY_THIN_VSESSION_PROGRAM,
                "devrel-developerhub-java-jdbc-token-auth");
        ds.setConnectionProperty(OracleConnection.CONNECTION_PROPERTY_CONFIG_FILE,
                file.toAbsolutePath().toString());
        return ds;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1)
            throw new IllegalArgumentException("Usage: NativeConfigFileDemo <trusted-properties-file>");
        String url = System.getenv("ADB_JDBC_URL");
        if (url == null || url.isBlank())
            throw new IllegalArgumentException("Set ADB_JDBC_URL to a TCPS EZConnect+ URL");
        try (var connection = dataSource(url, Path.of(args[0])).getConnection();
             var statement = connection.prepareStatement(
                     "SELECT SYS_CONTEXT('USERENV','SESSION_USER'), "
                     + "SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD') FROM dual")) {
            try (var rows = statement.executeQuery()) {
                if (rows.next()) System.out.println("Session user: " + rows.getString(1)
                        + "; authentication: " + rows.getString(2));
            }
        } catch (SQLException failure) {
            // Avoid exposing provider messages, tokens, paths or connection details.
            System.err.println("Connection/query failed; Oracle error code: " + failure.getErrorCode());
            System.exit(1);
        }
    }
}
