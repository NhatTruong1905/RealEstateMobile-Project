package com.ndnt.services.storage;

import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;
import java.net.InetSocketAddress;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import static org.junit.jupiter.api.Assertions.*;

class R2GalleryHttpTest {
    @Test void listsPaginatedPropertyObjectsAndUsesTheSdkForUploadAndDelete() throws Exception {
        String first = "properties/42/1761318000000-00-11111111-1111-1111-1111-111111111111.jpg";
        String second = "properties/42/1761318000000-01-22222222-2222-2222-2222-222222222222.png";
        var requests = new CopyOnWriteArrayList<String>();
        var failures = new CopyOnWriteArrayList<Throwable>();
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/", exchange -> {
            try {
                requests.add(exchange.getRequestMethod() + " " + exchange.getRequestURI());
                assertTrue(exchange.getRequestHeaders().getFirst("Authorization").contains("Credential=test-access/"));
                String response = "";
                if (exchange.getRequestMethod().equals("GET")) {
                    String query = exchange.getRequestURI().getRawQuery();
                    assertTrue(query.contains("prefix=properties%2F42%2F"));
                    boolean next = query.contains("continuation-token=next-page");
                    response = "<ListBucketResult xmlns=\"http://s3.amazonaws.com/doc/2006-03-01/\">"
                            + "<IsTruncated>" + !next + "</IsTruncated>"
                            + (next ? "" : "<NextContinuationToken>next-page</NextContinuationToken>")
                            + "<Contents><Key>" + (next ? second : first) + "</Key><Size>12</Size></Contents>"
                            + "<Contents><Key>properties/42/notes.txt</Key><Size>1</Size></Contents>"
                            + "</ListBucketResult>";
                } else if (exchange.getRequestMethod().equals("PUT")) {
                    assertEquals("image/jpeg", exchange.getRequestHeaders().getFirst("Content-Type"));
                    assertEquals(R2ObjectStorage.CACHE_CONTROL, exchange.getRequestHeaders().getFirst("Cache-Control"));
                    assertTrue(exchange.getRequestBody().readAllBytes().length > 0);
                }
                byte[] bytes = response.getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().set("Content-Type", "application/xml");
                exchange.sendResponseHeaders(200, bytes.length == 0 ? -1 : bytes.length);
                if (bytes.length > 0) exchange.getResponseBody().write(bytes);
            } catch (Throwable ex) { failures.add(ex); }
            finally { exchange.close(); }
        });
        server.start();
        try (S3Client client = S3Client.builder()
                .endpointOverride(URI.create("http://127.0.0.1:" + server.getAddress().getPort()))
                .region(Region.of("auto"))
                .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create("test-access", "test-secret")))
                .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build()).build()) {
            var storage = new R2ObjectStorage(client, "media-test", "https://images.example.invalid/");
            assertEquals(List.of(storage.publicUrl(first), storage.publicUrl(second)), storage.listPropertyImages(42));
            storage.put(first, new ImageProcessor().process(ImageProcessorTest.image(), false));
            storage.delete(first);
            assertEquals(4, requests.size());
            assertTrue(requests.get(2).startsWith("PUT /media-test/properties/42/"));
            assertTrue(requests.get(3).startsWith("DELETE /media-test/properties/42/"));
            assertTrue(failures.isEmpty(), failures.toString());
        } finally { server.stop(0); }
    }
}
