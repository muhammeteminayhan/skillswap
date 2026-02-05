package com.skillswap.backend.backend.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Component
public class GeminiClient {

    private static final Logger log = LoggerFactory.getLogger(GeminiClient.class);
    private static final String ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

    private final RestClient restClient;
    private final ObjectMapper objectMapper;
    private final String apiKey;

    public GeminiClient(@Value("${gemini.api.key:}") String apiKey, ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.apiKey = apiKey;
        log.info("GeminiClient initialized, keyPresent={}", apiKey != null && !apiKey.isBlank());

        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(Duration.ofSeconds(10));
        requestFactory.setReadTimeout(Duration.ofSeconds(10));

        this.restClient = RestClient.builder()
                .baseUrl(ENDPOINT)
                .defaultHeader("Content-Type", MediaType.APPLICATION_JSON_VALUE)
                .requestFactory(requestFactory)
                .build();
    }

    public Optional<String> generateContent(String prompt) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("Gemini API key missing");
            return Optional.empty();
        }

        Map<String, Object> payload = Map.of(
                "contents", List.of(
                        Map.of("parts", List.of(
                                Map.of("text", prompt)
                        ))
                )
        );

        try {
            ResponseEntity<String> response = restClient.post()
                    .uri(uriBuilder -> uriBuilder.queryParam("key", apiKey).build())
                    .body(payload)
                    .exchange((req, res) -> ResponseEntity.status(res.getStatusCode())
                            .headers(res.getHeaders())
                            .body(res.bodyTo(String.class)));

            HttpStatusCode status = response.getStatusCode();
            String body = response.getBody();

            if (!status.is2xxSuccessful()) {
                log.error("Gemini non-OK status: {}, body: {}", status.value(), body);
                return Optional.empty();
            }

            if (body == null) {
                log.error("Gemini empty body with status 200");
                return Optional.empty();
            }

            JsonNode root = objectMapper.readTree(body);
            JsonNode textNode = root.path("candidates")
                    .path(0)
                    .path("content")
                    .path("parts")
                    .path(0)
                    .path("text");

            if (textNode.isMissingNode() || textNode.isNull()) {
                log.error("Gemini response missing text node: {}", body);
                return Optional.empty();
            }

            return Optional.ofNullable(textNode.asText());
        } catch (Exception e) {
            log.error("Gemini call failed", e);
            return Optional.empty();
        }
    }
}
