package com.ndnt.configs;

import com.ndnt.services.storage.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.*;
import software.amazon.awssdk.auth.credentials.*;
import software.amazon.awssdk.core.client.config.ClientOverrideConfiguration;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.*;
import software.amazon.awssdk.core.checksums.RequestChecksumCalculation;
import software.amazon.awssdk.core.checksums.ResponseChecksumValidation;
import java.net.URI;
import java.time.Duration;

@Configuration
public class StorageConfiguration {
    @Bean
    ObjectStorage objectStorage(org.springframework.beans.factory.ObjectProvider<S3Client> r2,
                                @Value("${storage.r2.bucket:}") String bucket,
                                @Value("${storage.r2.public-base-url:}") String baseUrl) {
        require(!bucket.isBlank() && bucket.matches("[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]"), "R2_BUCKET");
        URI uri = https(baseUrl, "R2_PUBLIC_BASE_URL");
        require(uri.getQuery() == null && uri.getFragment() == null && uri.getUserInfo() == null
                && (uri.getPath().isEmpty() || uri.getPath().equals("/")), "R2_PUBLIC_BASE_URL");
        require(!uri.getHost().endsWith("r2.cloudflarestorage.com"), "R2_PUBLIC_BASE_URL phải là domain ảnh công khai");
        require(baseUrl.length() <= 150, "R2_PUBLIC_BASE_URL tối đa 150 ký tự");
        return new R2ObjectStorage(r2.getObject(), bucket, baseUrl);
    }

    @Bean(destroyMethod="close")
    S3Client r2Client(@Value("${storage.r2.account-id:}") String account,
                      @Value("${storage.r2.endpoint:}") String configuredEndpoint,
                      @Value("${storage.r2.access-key-id:}") String access,
                      @Value("${storage.r2.secret-access-key:}") String secret) {
        require(!access.isBlank(), "R2_ACCESS_KEY_ID"); require(!secret.isBlank(), "R2_SECRET_ACCESS_KEY");
        require(!configuredEndpoint.isBlank() || account.matches("[0-9a-fA-F]{32}"), "R2_ACCOUNT_ID hoặc R2_ENDPOINT");
        URI endpoint = https(configuredEndpoint.isBlank() ? "https://" + account + ".r2.cloudflarestorage.com" : configuredEndpoint, "R2_ENDPOINT");
        require(endpoint.getQuery() == null && endpoint.getUserInfo() == null && endpoint.getFragment() == null
                && (endpoint.getPath().isEmpty() || endpoint.getPath().equals("/")), "R2_ENDPOINT");
        return S3Client.builder().endpointOverride(endpoint).region(Region.of("auto"))
                .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create(access, secret)))
                .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).chunkedEncodingEnabled(false).build())
                .requestChecksumCalculation(RequestChecksumCalculation.WHEN_REQUIRED)
                .responseChecksumValidation(ResponseChecksumValidation.WHEN_REQUIRED)
                .httpClientBuilder(UrlConnectionHttpClient.builder().connectionTimeout(Duration.ofSeconds(3)).socketTimeout(Duration.ofSeconds(5)))
                .overrideConfiguration(ClientOverrideConfiguration.builder().apiCallAttemptTimeout(Duration.ofSeconds(8))
                        .apiCallTimeout(Duration.ofSeconds(20)).build()).build();
    }
    private static URI https(String value, String name) {
        try {
            URI uri = URI.create(value);
            require("https".equals(uri.getScheme()) && uri.getHost() != null, name);
            return uri;
        } catch (IllegalArgumentException ex) { throw new IllegalStateException("Thiếu hoặc sai cấu hình " + name); }
    }
    private static void require(boolean valid, String name) {
        if (!valid) throw new IllegalStateException("Thiếu hoặc sai cấu hình " + name);
    }
}
