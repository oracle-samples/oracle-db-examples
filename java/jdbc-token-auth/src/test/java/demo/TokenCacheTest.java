package demo;

import oracle.jdbc.AccessToken;
import org.junit.jupiter.api.Test;
import java.nio.charset.StandardCharsets;
import java.security.KeyPairGenerator;
import java.security.Signature;
import java.time.Instant;
import java.util.Base64;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import static org.junit.jupiter.api.Assertions.*;

class TokenCacheTest {
    @Test void concurrentBorrowersShareOneAcquisition() throws Exception {
        checkConcurrentCache(true);
    }

    @Test void entraBearerCacheDoesNotRequireProofOfPossessionKey() throws Exception {
        checkConcurrentCache(false);
    }

    private void checkConcurrentCache(boolean proofOfPossession) throws Exception {
        // Locally signed synthetic token: never sent to a cloud or database.
        var gen = KeyPairGenerator.getInstance("RSA");
        gen.initialize(2048);
        var pair = gen.generateKeyPair();
        var b64 = Base64.getUrlEncoder().withoutPadding();
        String header = b64.encodeToString("{\"alg\":\"RS256\"}".getBytes(StandardCharsets.UTF_8));
        String body = b64.encodeToString(("{\"exp\":" + (Instant.now().getEpochSecond()+3600) + "}").getBytes(StandardCharsets.UTF_8));
        String input = header + "." + body;
        var signer = Signature.getInstance("SHA256withRSA");
        signer.initSign(pair.getPrivate());
        signer.update(input.getBytes(StandardCharsets.US_ASCII));
        char[] jwt = (input + "." + b64.encodeToString(signer.sign())).toCharArray();
        var token = proofOfPossession ? AccessToken.createJsonWebToken(jwt, pair.getPrivate())
                : AccessToken.createJsonWebToken(jwt);
        var requests = new AtomicInteger();
        var cache = AccessToken.createJsonWebTokenCache(() -> {requests.incrementAndGet(); return token;});
        var workers = Executors.newFixedThreadPool(8);
        try {
            var jobs = new java.util.ArrayList<java.util.concurrent.Callable<AccessToken>>();
            for (int i=0; i<32; i++) jobs.add(cache::get);
            for (var result : workers.invokeAll(jobs)) assertArrayEquals(token.toCharArray(), result.get().toCharArray());
            assertEquals(1, requests.get());
        } finally {workers.shutdownNow();}
    }
}
