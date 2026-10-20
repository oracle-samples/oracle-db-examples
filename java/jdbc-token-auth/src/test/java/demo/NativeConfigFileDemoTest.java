package demo;

import java.nio.file.Path;
import oracle.jdbc.OracleConnection;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class NativeConfigFileDemoTest {
    @Test void nativeProfilesContainOnlyJdbcProperties() throws Exception {
        for (String name : java.util.List.of("native-oci-instance.properties", "native-entra-managed.properties")) {
            var properties = new java.util.Properties();
            try (var reader = java.nio.file.Files.newBufferedReader(Path.of("config", name))) {
                properties.load(reader);
            }
            assertNotNull(properties.getProperty("oracle.jdbc.tokenAuthentication"));
            assertTrue(properties.stringPropertyNames().stream()
                    .allMatch(key -> key.startsWith("oracle.jdbc.") || key.startsWith("oracle.net.")));
            assertTrue(properties.values().stream().anyMatch(value -> value.toString().startsWith("${")));
        }
    }
    @Test void delegatesFileLoadingToDriver() throws Exception {
        Path file = Path.of("config/native-oci-instance.properties");
        var ds = NativeConfigFileDemo.dataSource(
                "jdbc:oracle:thin:@tcps://example.invalid:1522/service", file);
        assertEquals(file.toAbsolutePath().toString(), ds.getConnectionProperties()
                .getProperty(OracleConnection.CONNECTION_PROPERTY_CONFIG_FILE));
        assertNull(ds.getConnectionProperties().getProperty("oracle.jdbc.ociDatabase"));
    }
    @Test void rejectsNonTlsUrl() {
        assertThrows(IllegalArgumentException.class, () -> NativeConfigFileDemo.dataSource(
                "jdbc:oracle:thin:@//example.invalid:1521/service",
                Path.of("config/native-oci-instance.properties")));
    }
}
