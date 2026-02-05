package com.skillswap.backend.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

@Service
public class MlModelService {

    private final ObjectMapper objectMapper;

    private String version = "unknown";
    private double fairnessIntercept;
    private double fairnessHours;
    private double fairnessDifficulty;
    private double fairnessRisk;
    private int tokenRate = 10;

    private double churnIntercept;
    private double churnDaysInactive;
    private double churnOpenRequests;
    private double churnUnreadMessages;
    private double churnTrustScore;

    private double semanticWantOverlap = 0.5;
    private double semanticOfferOverlap = 0.3;
    private double semanticTrust = 0.15;
    private double semanticReciprocity = 0.05;

    private final Map<String, List<String>> semanticCategories = new HashMap<>();

    public MlModelService(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public void load() {
        try {
            ClassPathResource resource = new ClassPathResource("ml/skillswap-model.json");
            try (InputStream is = resource.getInputStream()) {
                JsonNode root = objectMapper.readTree(is);
                version = root.path("version").asText("unknown");

                JsonNode fairness = root.path("fairnessModel");
                fairnessIntercept = fairness.path("intercept").asDouble(0);
                fairnessHours = fairness.path("hours").asDouble(1);
                fairnessDifficulty = fairness.path("difficulty").asDouble(1);
                fairnessRisk = fairness.path("risk").asDouble(1);
                tokenRate = fairness.path("tokenRate").asInt(10);

                JsonNode churn = root.path("churnModel");
                churnIntercept = churn.path("intercept").asDouble(-1);
                churnDaysInactive = churn.path("daysInactive").asDouble(0.05);
                churnOpenRequests = churn.path("openRequests").asDouble(0.2);
                churnUnreadMessages = churn.path("unreadMessages").asDouble(0.1);
                churnTrustScore = churn.path("trustScore").asDouble(-0.03);

                JsonNode semanticWeights = root.path("semantic").path("weights");
                semanticWantOverlap = semanticWeights.path("wantOverlap").asDouble(semanticWantOverlap);
                semanticOfferOverlap = semanticWeights.path("offerOverlap").asDouble(semanticOfferOverlap);
                semanticTrust = semanticWeights.path("trust").asDouble(semanticTrust);
                semanticReciprocity = semanticWeights.path("reciprocity").asDouble(semanticReciprocity);

                semanticCategories.clear();
                JsonNode categoriesNode = root.path("semantic").path("categories");
                Iterator<String> fields = categoriesNode.fieldNames();
                while (fields.hasNext()) {
                    String field = fields.next();
                    List<String> keywords = objectMapper.convertValue(categoriesNode.path(field), List.class);
                    semanticCategories.put(field, keywords);
                }
            }
        } catch (Exception e) {
            // keep defaults when model file is missing/corrupt
        }
    }

    public String getVersion() {
        return version;
    }

    public int tokenRate() {
        return tokenRate;
    }

    public double predictTaskValue(double hours, int difficulty, int risk) {
        return fairnessIntercept + fairnessHours * hours + fairnessDifficulty * difficulty + fairnessRisk * risk;
    }

    public double predictChurnProbability(int daysInactive, int openRequests, int unreadMessages, int trustScore) {
        double z = churnIntercept
                + churnDaysInactive * daysInactive
                + churnOpenRequests * openRequests
                + churnUnreadMessages * unreadMessages
                + churnTrustScore * trustScore;
        return 1.0 / (1.0 + Math.exp(-z));
    }

    public double semanticScore(int wantOverlap, int offerOverlap, int trustScore, boolean reciprocal) {
        double normalizedTrust = Math.max(0, Math.min(100, trustScore)) / 100.0;
        double score = semanticWantOverlap * Math.min(1.0, wantOverlap / 3.0)
                + semanticOfferOverlap * Math.min(1.0, offerOverlap / 3.0)
                + semanticTrust * normalizedTrust
                + semanticReciprocity * (reciprocal ? 1.0 : 0.0);
        return Math.max(0.0, Math.min(1.0, score));
    }

    public Map<String, List<String>> semanticCategories() {
        return semanticCategories;
    }
}
