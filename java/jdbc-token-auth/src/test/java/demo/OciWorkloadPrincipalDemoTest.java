package demo;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class OciWorkloadPrincipalDemoTest {
    private Map<String, String> env() {
        return new HashMap<>(Map.of("ADB_JDBC_URL", "jdbc:oracle:thin:@tcps://db.example.test:1521/service_low",
                "OCI_COMPARTMENT_ID", "compartment-placeholder", "OCI_DATABASE_ID", "database-placeholder",
                "EXPECTED_DB_USER", "TOKEN_INSTANCE_DEMO"));
    }

    @Test void selectsOnlyInstanceProvider() {
        var settings = OciWorkloadPrincipalDemo.configure("instance", env());
        assertEquals("OCI_INSTANCE_PRINCIPAL", settings.properties().getProperty("oracle.jdbc.tokenAuthentication"));
        assertEquals(5, settings.properties().size());
        assertFalse(settings.properties().containsKey("oracle.jdbc.provider.accessToken"));
        assertFalse(settings.properties().containsKey("oracle.jdbc.ociConfigFile"));
    }

    @Test void selectsOnlyResourceProviderEvenIfApiKeyEnvironmentExists() {
        var env = env();
        env.put("OCI_CONFIG_FILE", "/not-used/config");
        env.put("OCI_PROFILE", "DEFAULT");
        var settings = OciWorkloadPrincipalDemo.configure("resource", env);
        assertEquals("OCI_RESOURCE_PRINCIPAL", settings.properties().getProperty("oracle.jdbc.tokenAuthentication"));
        assertEquals(5, settings.properties().size());
    }

    @Test void rejectsDefaultAndApiKeySelection() {
        for (String mode : new String[]{"default", "api-key", "", "OCI_DEFAULT"})
            assertThrows(IllegalArgumentException.class, () -> OciWorkloadPrincipalDemo.configure(mode, env()));
    }

    @Test void requiresAllScopeAndIdentityInputs() {
        for (String key : env().keySet()) {
            var missing = env(); missing.remove(key);
            assertThrows(IllegalArgumentException.class, () -> OciWorkloadPrincipalDemo.configure("instance", missing));
        }
    }

    @Test void rejectsInsecureUrls() {
        for (String url : new String[]{"jdbc:oracle:thin:@tcp://db:1521/service", "jdbc:oracle:thin:@alias",
                "jdbc:oracle:thin:@tcps://db:1521/service?ssl_server_dn_match=false"}) {
            var bad = env(); bad.put("ADB_JDBC_URL", url);
            assertThrows(IllegalArgumentException.class, () -> OciWorkloadPrincipalDemo.configure("instance", bad));
        }
    }

    @Test void enforcesExpectedGlobalTokenIdentity() throws Exception {
        OciWorkloadPrincipalDemo.verifyIdentity("TOKEN_INSTANCE_DEMO", "TOKEN_INSTANCE_DEMO", "TOKEN_GLOBAL");
        assertThrows(SQLException.class, () -> OciWorkloadPrincipalDemo.verifyIdentity("TOKEN_INSTANCE_DEMO", "ADMIN", "TOKEN_GLOBAL"));
        assertThrows(SQLException.class, () -> OciWorkloadPrincipalDemo.verifyIdentity("TOKEN_INSTANCE_DEMO", "TOKEN_INSTANCE_DEMO", "PASSWORD"));
    }

    @Test void rejectsQuotedOrMixedCaseExpectedUser() {
        var bad = env(); bad.put("EXPECTED_DB_USER", "Wrong user");
        assertThrows(IllegalArgumentException.class, () -> OciWorkloadPrincipalDemo.configure("resource", bad));
    }
}
