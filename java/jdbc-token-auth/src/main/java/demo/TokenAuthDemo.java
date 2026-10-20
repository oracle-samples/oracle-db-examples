package demo;

import oracle.jdbc.AccessToken;
import oracle.jdbc.datasource.impl.OracleDataSource;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.Executors;
import java.util.function.Supplier;

/** Executable JDBC, builder, and concurrent UCP authentication demonstrations. */
public final class TokenAuthDemo {
    public static void main(String[] args) {
        if (args.length == 0 || args[0].equals("--help")) {
            System.out.println("Usage: run.sh CONFIG [check|jdbc|builder|ucp|ucp-fresh] [rounds=1] [pauseSeconds=0]");
            return;
        }
        try {
            if (args.length > 4) throw new IllegalArgumentException("Too many arguments");
            String action = args.length > 1 ? args[1] : "jdbc";
            if (!java.util.Set.of("check", "jdbc", "builder", "ucp", "ucp-fresh").contains(action))
                throw new IllegalArgumentException("Unknown action; use --help");
            int rounds = args.length > 2 ? Integer.parseInt(args[2]) : 1;
            int pause = args.length > 3 ? Integer.parseInt(args[3]) : 0;
            if (rounds < 1 || rounds > 10000 || pause < 0 || pause > 86400)
                throw new IllegalArgumentException("rounds: 1..10000; pauseSeconds: 0..86400");
            Settings config = Settings.load(Path.of(args[0]), System.getenv());
            if (action.equals("builder") && !java.util.Set.of("sdk", "entra-sdk").contains(config.mode()))
                throw new IllegalArgumentException("builder requires SDK mode");
            if (action.equals("check")) {
                System.out.println("Configuration valid: mode=" + config.mode() + "; no cloud or database connection attempted");
                return;
            }
            Supplier<? extends AccessToken> tokens = switch (config.mode()) {
                case "sdk" -> OciTokens.cached(config.app());
                case "entra-sdk" -> action.equals("builder") ? EntraTokens.supplier(config.app()) : EntraTokens.cached(config.app());
                default -> null;
            };
            if (action.startsWith("ucp")) runPool(config, tokens, action.equals("ucp-fresh"), rounds, pause);
            else {
                OracleDataSource ds = new OracleDataSource();
                ds.setURL(config.url());
                ds.setConnectionProperties(config.jdbc());
                if (tokens != null && !action.equals("builder")) ds.setTokenSupplier(tokens);
                for (int round = 1; round <= rounds; round++) {
                    try (Connection c = action.equals("builder")
                            ? ds.createConnectionBuilder().accessToken(config.mode().equals("sdk")
                                ? OciTokens.request(config.app()) : tokens.get()).build()
                            : ds.getConnection()) {
                        query(c, round);
                    }
                    if (round < rounds) Thread.sleep(pause * 1000L);
                }
            }
        } catch (Exception failure) {
            if (failure instanceof InterruptedException) Thread.currentThread().interrupt();
            if (failure instanceof IllegalArgumentException) System.err.println(failure.getMessage());
            else {
                Throwable cause = failure;
                while (cause.getCause() != null) cause = cause.getCause();
                System.err.println("Run failed: " + cause.getClass().getSimpleName());
                if (cause instanceof SQLException sql)
                    System.err.println("Oracle error code=" + sql.getErrorCode() + "; SQLState=" + sql.getSQLState());
                if (cause instanceof oracle.ucp.UniversalConnectionPoolException poolFailure)
                    System.err.println("UCP error code=" + poolFailure.getErrorCode());
                System.err.println("See docs/troubleshooting.md. Credential values and exception payloads are not logged.");
            }
            System.exit(1);
        }
    }

    static PoolDataSource pool(Settings config, Supplier<? extends AccessToken> tokens, boolean fresh) throws SQLException {
        PoolDataSource ds = PoolDataSourceFactory.getPoolDataSource();
        ds.setConnectionPoolName("TokenAuthDemo");
        ds.setConnectionFactoryClassName(OracleDataSource.class.getName());
        ds.setURL(config.url());
        ds.setConnectionProperties(config.jdbc());
        ds.setInitialPoolSize(0);
        ds.setMinPoolSize(0);
        ds.setMaxPoolSize(2);
        ds.setConnectionWaitDuration(java.time.Duration.ofSeconds(fresh ? 60 : 20));
        ds.setValidateConnectionOnBorrow(true);
        if (tokens != null) ds.setTokenSupplier(tokens);
        // Diagnostic mode purges only between completed rounds, with no borrowers.
        return ds;
    }

    private static void runPool(Settings config, Supplier<? extends AccessToken> tokens,
                                boolean fresh, int rounds, int pause) throws Exception {
        PoolDataSource ds = pool(config, tokens, fresh);
        var executor = Executors.newFixedThreadPool(2);
        try {
            for (int round = 1; round <= rounds; round++) {
                final int current = round;
                List<Callable<Void>> tasks = new ArrayList<>();
                for (int i = 0; i < 4; i++) tasks.add(() -> {
                    try (Connection c = ds.getConnection()) {
                        query(c, current);
                    }
                    return null;
                });
                for (var result : executor.invokeAll(tasks)) result.get();
                if (fresh) {
                    // Keep the same data source/token cache, but retire all physical
                    // sessions after all workers have returned their connections.
                    UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager()
                            .purgeConnectionPool(ds.getConnectionPoolName());
                    if (ds.getAvailableConnectionsCount() != 0 || ds.getBorrowedConnectionsCount() != 0)
                        throw new IllegalStateException("Diagnostic purge did not empty the pool");
                    System.out.println("round=" + round + " poolPurged=true available=0 borrowed=0");
                }
                if (round < rounds) Thread.sleep(pause * 1000L);
            }
        } finally {
            executor.shutdownNow();
            if (java.util.Arrays.asList(UniversalConnectionPoolManagerImpl
                    .getUniversalConnectionPoolManager().getConnectionPoolNames()).contains(ds.getConnectionPoolName()))
                UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager()
                        .destroyConnectionPool(ds.getConnectionPoolName());
        }
    }

    private static void query(Connection connection, int round) throws SQLException {
        try (var statement = connection.prepareStatement("""
                SELECT SYS_CONTEXT('USERENV','SESSION_USER'),
                       SYS_CONTEXT('USERENV','AUTHENTICATED_IDENTITY'),
                       SYS_CONTEXT('USERENV','AUTHENTICATION_METHOD'),
                       SYS_CONTEXT('USERENV','SID'), ? FROM dual
                """)) {
            statement.setInt(1, round);
            try (var rows = statement.executeQuery()) {
                if (!rows.next()) throw new SQLException("Identity query returned no rows");
                System.out.printf("round=%d user=%s identity=%s authentication=%s sid=%s%n",
                        rows.getInt(5), rows.getString(1), rows.getString(2), rows.getString(3), rows.getString(4));
            }
        }
    }
}
