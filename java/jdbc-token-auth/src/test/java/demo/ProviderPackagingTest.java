package demo;

import org.junit.jupiter.api.Test;
import oracle.jdbc.spi.AccessTokenProvider;
import java.util.ServiceLoader;
import java.util.stream.Collectors;
import static org.junit.jupiter.api.Assertions.*;

class ProviderPackagingTest {
    @Test void runtimeContainsBothTokenProviders() {
        var names = ServiceLoader.load(AccessTokenProvider.class).stream()
                .map(p -> p.get().getName()).collect(Collectors.toSet());
        assertTrue(names.contains("ojdbc-provider-oci-token"), names.toString());
        assertTrue(names.contains("ojdbc-provider-azure-token"), names.toString());
    }
}
