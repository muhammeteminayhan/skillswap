package com.skillswap.backend.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.skillswap.backend.backend.ai.GeminiClient;
import com.skillswap.backend.backend.dto.ExtractResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ExtractService {

    private static final Logger logger = LoggerFactory.getLogger(ExtractService.class);

    private static final String PROMPT_TEMPLATE = """
            Sen bir metin analiz motorusun.
            SADECE GEÇERLİ JSON döndür.
            Markdown, açıklama, başlık, kod bloğu (```json, ```) kullanma.
            Cevap tek bir JSON obje olmalı ve TÜM alanlar dolu olmalı.

            Kurallar:
            - wants ve offers alanları Türkçe skill/hizmet isimleri olsun.
              Örnek: "Elektrik - priz", "Doğalgaz - kombi bakımı", "Tesisat - musluk tamiri".
            - urgency sadece: "low", "medium", "high".
            - estimatedTimeHours sayısal değer olsun (ondalıklı olabilir).
            - difficulty ve risk 1-5 arasında integer olsun.
            - locationHint metinden il/ilçe/mahalle tespit edilirse yaz, yoksa "".
            - Alan isimleri birebir şu formatta olmalı:
            {
              "wants": [],
              "offers": [],
              "urgency": "low|medium|high",
              "estimatedTimeHours": 1.0,
              "difficulty": 1,
              "risk": 1,
              "locationHint": ""
            }

            Metin:
            <<<KULLANICI_METNI>>>
            """;

    private final GeminiClient geminiClient;
    private final ObjectMapper objectMapper;

    public ExtractService(GeminiClient geminiClient, ObjectMapper objectMapper) {
        this.geminiClient = geminiClient;
        this.objectMapper = objectMapper;
    }

    public ExtractResponse extract(String text) {
        String prompt = PROMPT_TEMPLATE.replace("<<<KULLANICI_METNI>>>", text == null ? "" : text);

        Optional<String> rawOpt = geminiClient.generateContent(prompt);
        if (rawOpt.isPresent()) {
            String rawText = rawOpt.get();
            logger.info("GEMINI_RAW_RESPONSE={}", rawText);
            try {
                String cleaned = cleanJson(rawText);
                ExtractResponse parsed = objectMapper.readValue(cleaned, ExtractResponse.class);
                ExtractResponse normalized = normalize(parsed);
                logger.info("PARSED_EXTRACT_RESPONSE={}", normalized);
                return normalized;
            } catch (Exception e) {
                logger.warn("GEMINI_ERROR", e);
            }
        }

        return fallbackResponse();
    }

    private String cleanJson(String rawText) {
        if (rawText == null) {
            return "";
        }
        String cleaned = rawText.replace("```json", "").replace("```", "").trim();
        if (cleaned.startsWith("json")) {
            cleaned = cleaned.substring(4).trim();
        }
        return cleaned;
    }

    private ExtractResponse normalize(ExtractResponse response) {
        ExtractResponse normalized = response == null ? new ExtractResponse() : response;

        if (normalized.getWants() == null) {
            normalized.setWants(List.of());
        }
        if (normalized.getOffers() == null) {
            normalized.setOffers(List.of());
        }
        if (normalized.getUrgency() == null || normalized.getUrgency().isBlank()) {
            normalized.setUrgency("medium");
        }
        if (normalized.getEstimatedTimeHours() == null || normalized.getEstimatedTimeHours() <= 0) {
            normalized.setEstimatedTimeHours(1.0);
        }
        if (normalized.getDifficulty() == null) {
            normalized.setDifficulty(2);
        }
        if (normalized.getRisk() == null) {
            normalized.setRisk(2);
        }
        normalized.setDifficulty(clampRange(normalized.getDifficulty()));
        normalized.setRisk(clampRange(normalized.getRisk()));

        if (normalized.getLocationHint() == null) {
            normalized.setLocationHint("");
        }

        return normalized;
    }

    private int clampRange(int value) {
        if (value < 1) {
            return 1;
        }
        return Math.min(value, 5);
    }

    private ExtractResponse fallbackResponse() {
        ExtractResponse response = new ExtractResponse();
        response.setWants(List.of());
        response.setOffers(List.of());
        response.setUrgency("medium");
        response.setEstimatedTimeHours(1.0);
        response.setDifficulty(2);
        response.setRisk(2);
        response.setLocationHint("");
        return response;
    }
}
