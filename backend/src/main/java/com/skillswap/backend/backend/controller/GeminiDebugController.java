package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.ai.GeminiClient;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GeminiDebugController {

    private final GeminiClient geminiClient;

    public GeminiDebugController(GeminiClient geminiClient) {
        this.geminiClient = geminiClient;
    }

    @GetMapping("/gemini/ping")
    public ResponseEntity<String> ping() {
        return geminiClient.generateContent("Sadece OK yaz. Başka bir şey yazma.")
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(500).body("GEMINI_EMPTY"));
    }
}
