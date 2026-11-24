package com.ndnt.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestClientResponseException;

import java.time.Duration;
import java.util.List;

@Component
public class ResendMailClient {
    private final RestClient client;
    private final String apiKey;
    private final String from;

    @Autowired
    public ResendMailClient(@Value("${resend.api-key:}") String apiKey,
                            @Value("${resend.from:}") String from) {
        this(apiClient(), apiKey, from);
    }

    ResendMailClient(RestClient client, String apiKey, String from) {
        this.client = client;
        this.apiKey = apiKey.strip();
        this.from = from.strip();
    }

    private static RestClient apiClient() {
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(5));
        factory.setReadTimeout(Duration.ofSeconds(10));
        return RestClient.builder().baseUrl("https://api.resend.com").requestFactory(factory).build();
    }

    public void send(String recipient, String subject, String text, String html, String idempotencyKey) {
        if (apiKey.isBlank() || from.isBlank()) {
            throw new IllegalStateException("RESEND_API_KEY and RESEND_FROM must be configured");
        }
        var request = client.post().uri("/emails")
                .headers(headers -> headers.setBearerAuth(apiKey))
                .contentType(MediaType.APPLICATION_JSON);
        if (idempotencyKey != null) request.header("Idempotency-Key", idempotencyKey);
        try {
            var sent = request.body(new SendEmail(from, List.of(recipient), subject, text, html))
                    .retrieve().body(SendResult.class);
            if (sent == null || sent.id() == null || sent.id().isBlank()) {
                throw new IllegalStateException("Resend response is missing an email ID");
            }
        } catch (RestClientResponseException failure) {
            throw new IllegalStateException("Resend HTTP " + failure.getStatusCode().value());
        } catch (RestClientException failure) {
            throw new IllegalStateException("Resend request failed");
        }
    }

    private record SendEmail(String from, List<String> to, String subject, String text, String html) {
        @Override public String toString() {
            return "Resend email payload";
        }
    }
    private record SendResult(String id) {}
}
