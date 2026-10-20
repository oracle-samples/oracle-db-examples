package demo;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;

class SettingsTest {
    @TempDir Path temp;
    private static final String BASE = "app.url=jdbc:oracle:thin:@tcps://example.invalid:1522/service\napp.mode=file\noracle.jdbc.tokenAuthentication=OCI_TOKEN\noracle.jdbc.tokenLocation=/tmp/tokens\n";
    private Settings load(String text, Map<String,String> env) throws Exception {
        Path file = temp.resolve("test.properties");
        Files.writeString(file, text);
        return Settings.load(file, env);
    }
    @Test void substitutesWithoutInterpretingSecretCharacters() throws Exception {
        var s = load(BASE + "oracle.jdbc.tokenLocation=${TOKEN_DIR}\n", Map.of("TOKEN_DIR", "/tmp/a$b\\c"));
        assertEquals("/tmp/a$b\\c", s.jdbc().getProperty("oracle.jdbc.tokenLocation"));
    }
    @Test void missingVariableNamesOnlyTheVariable() {
        var error = assertThrows(IllegalArgumentException.class, () -> load(BASE + "oracle.jdbc.tokenLocation=${TOKEN_DIR}\n", Map.of()));
        assertEquals("Set environment variable TOKEN_DIR", error.getMessage());
    }
    @Test void rejectsPlaintextTransport() {
        assertThrows(IllegalArgumentException.class, () -> load(BASE.replace("tcps://", "tcp://"), Map.of()));
    }
    @Test void rejectsUrlPropertyOverrides() {
        assertThrows(IllegalArgumentException.class, () -> load(BASE.replace("/service", "/service?oracle.net.ssl_server_dn_match=false"), Map.of()));
    }
    @Test void enforcesServerIdentityVerification() throws Exception {
        assertThrows(IllegalArgumentException.class, () -> load(BASE + "oracle.net.ssl_server_dn_match=false\n", Map.of()));
        assertNull(load(BASE, Map.of()).jdbc().getProperty("oracle.net.ssl_server_dn_match"));
    }
    @Test void rejectsMixedTokenMechanisms() {
        assertThrows(IllegalArgumentException.class, () -> load(BASE + "oracle.jdbc.provider.accessToken=ojdbc-provider-oci-token\n", Map.of()));
    }
    @Test void rejectsDatabasePassword() {
        assertThrows(IllegalArgumentException.class, () -> load(BASE + "password=never-log-this\n", Map.of()));
        assertThrows(IllegalArgumentException.class, () -> load(BASE + "oracle.jdbc.password=never-log-this\n", Map.of()));
    }
    @Test void everyShippedProfileLoadsWithoutNetwork() throws Exception {
        var env = Map.ofEntries(Map.entry("ADB_JDBC_URL", "jdbc:oracle:thin:@tcps://example.invalid:1522/service"),
                Map.entry("OCI_DB_TOKEN_DIR", "/tmp/tokens"), Map.entry("ENTRA_DB_TOKEN_FILE", "/tmp/token"),
                Map.entry("OCI_CONFIG_FILE", "/tmp/oci-config"), Map.entry("OCI_PROFILE", "DEFAULT"),
                Map.entry("OCI_DB_SCOPE", "urn:oracle:db::id::compartment::database"),
                Map.entry("OCI_COMPARTMENT_ID", "compartment"), Map.entry("OCI_DATABASE_ID", "database"),
                Map.entry("ENTRA_DB_SCOPE", "https://example.invalid/db/.default"),
                Map.entry("ENTRA_DB_APP_ID_URI", "https://example.invalid/db"),
                Map.entry("AZURE_TENANT_ID", "tenant"), Map.entry("AZURE_CLIENT_ID", "client"));
        try (var files = Files.list(Path.of("config"))) {
            // Native JDBC files intentionally contain no application-specific app.* keys.
            for (Path file : files.filter(f -> f.toString().endsWith(".properties")
                    && !f.toString().endsWith(".local.properties")
                    && !f.getFileName().toString().startsWith("native-")).toList()) {
                var s = Settings.load(file, env);
                assertFalse(s.jdbc().containsKey("app.url"), file.toString());
            }
        }
    }
    @Test void acceptsEzconnectTransportOptions() throws Exception {
        var s=load(BASE.replace("/service", "/service?connect_timeout=10sec&retry_count=2"), Map.of());
        assertTrue(s.url().contains("connect_timeout=10sec"));
    }
    @Test void rejectsDescriptorsAliasesAndCredentialOverrides() {
        for(String url:java.util.List.of("jdbc:oracle:thin:@alias", "jdbc:oracle:thin:@(description=(address=(protocol=tcps)))",
                "jdbc:oracle:thin:@tcps://example.invalid:1522/service?user=ADMIN",
                "jdbc:oracle:thin:@tcps://example.invalid:1522/service?token_auth=OAUTH",
                "jdbc:oracle:thin:@tcps://example.invalid:1522/service?connect_timeout=10&connect_timeout=20"))
            assertThrows(IllegalArgumentException.class,()->load(BASE.replace("jdbc:oracle:thin:@tcps://example.invalid:1522/service",url),Map.of()));
    }
    @Test void supportsEntraFileWithoutPopKey() throws Exception {
        assertEquals("OAUTH",load(BASE.replace("OCI_TOKEN","OAUTH"),Map.of()).jdbc().getProperty("oracle.jdbc.tokenAuthentication"));
    }
    @Test void rejectsSupplierAndProviderConflict() {
        assertThrows(IllegalArgumentException.class,()->load(BASE.replace("app.mode=file","app.mode=entra-sdk"),Map.of()));
    }
    @Test void rejectsDirectTokenAndWalletCredentialOverrides() {
        for(String property:java.util.List.of("oracle.jdbc.accessToken", "oracle.jdbc.passwordAuthentication", "oracle.net.seps_wallet_location", "oracle.net.tns_admin"))
            assertThrows(IllegalArgumentException.class,()->load(BASE+property+"=invalid\n",Map.of()));
    }
    @Test void poolConfigurationDoesNotConnectAndForcesFreshSessionsOnlyWhenRequested() throws Exception {
        var s = load(BASE, Map.of());
        var ds = TokenAuthDemo.pool(s, null, true);
        assertEquals(2, ds.getMaxPoolSize());
        assertEquals(0, ds.getMaxConnectionReuseCount());
        assertEquals("OCI_TOKEN", ds.getConnectionProperties().getProperty("oracle.jdbc.tokenAuthentication"));
        assertNull(ds.getUser());
        assertEquals(0, TokenAuthDemo.pool(s, null, false).getMaxConnectionReuseCount());
    }
}
