package com.ndnt.controllers.api;

import com.ndnt.services.property.AIPropertySourceService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/internal/ai")
@RequiredArgsConstructor
public class AIPropertySourceController {
    private final AIPropertySourceService propertySource;
    @Value("${property.index.service-token:}")
    private String serviceToken;

    private void authorize(String supplied) {
        if (serviceToken.isBlank() || supplied == null || !MessageDigest.isEqual(
                serviceToken.getBytes(StandardCharsets.UTF_8), supplied.getBytes(StandardCharsets.UTF_8)))
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED);
    }

    @GetMapping("/properties/{id}")
    public Map<String, Object> get(@RequestHeader(value = "X-AI-Service-Token", required = false) String token,
                                   @PathVariable Integer id) {
        authorize(token);
        return propertySource.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND));
    }

    @GetMapping("/properties")
    public Map<String, Object> page(@RequestHeader(value = "X-AI-Service-Token", required = false) String token,
                                    @RequestParam(defaultValue = "0") Integer after,
                                    @RequestParam(defaultValue = "20") Integer limit) {
        authorize(token);
        if (after < 0 || limit < 1 || limit > 100) throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        return Map.of("records", propertySource.page(after, limit));
    }

    @GetMapping("/properties/resolve")
    public Map<String, Object> resolve(@RequestHeader(value = "X-AI-Service-Token", required = false) String token,
                                       @RequestParam List<Integer> ids) {
        authorize(token);
        if (ids.isEmpty() || ids.size() > 100 || ids.stream().anyMatch(id -> id == null || id < 1))
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST);
        return Map.of("records", propertySource.resolve(ids));
    }
}
