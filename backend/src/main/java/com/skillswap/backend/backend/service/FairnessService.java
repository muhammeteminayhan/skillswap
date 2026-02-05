package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.ExtractResponse;
import com.skillswap.backend.backend.dto.FairnessResponse;
import org.springframework.stereotype.Service;

@Service
public class FairnessService {

    private final ExtractService extractService;
    private final MlModelService mlModelService;

    public FairnessService(ExtractService extractService, MlModelService mlModelService) {
        this.extractService = extractService;
        this.mlModelService = mlModelService;
    }

    public FairnessResponse evaluate(String leftTaskText, String rightTaskText) {
        ExtractResponse left = extractService.extract(leftTaskText);
        ExtractResponse right = extractService.extract(rightTaskText);

        int leftValue = calculateValue(left);
        int rightValue = calculateValue(right);
        int max = Math.max(leftValue, rightValue);
        int min = Math.min(leftValue, rightValue);
        int fairnessPercent = max == 0 ? 100 : (int) Math.round((min * 100.0) / max);
        int deltaValue = Math.abs(leftValue - rightValue);
        int tokenSuggested = deltaValue * mlModelService.tokenRate();

        FairnessResponse response = new FairnessResponse();
        response.setLeftValue(leftValue);
        response.setRightValue(rightValue);
        response.setFairnessPercent(fairnessPercent);
        response.setDeltaValue(deltaValue);
        response.setTokenSuggested(tokenSuggested);
        response.setVerdict(verdictFor(fairnessPercent));
        response.setSuggestionText(suggestionFor(fairnessPercent, tokenSuggested));
        return response;
    }

    private int calculateValue(ExtractResponse response) {
        double hours = response.getEstimatedTimeHours() == null ? 1.0 : response.getEstimatedTimeHours();
        int difficulty = response.getDifficulty() == null ? 2 : response.getDifficulty();
        int risk = response.getRisk() == null ? 2 : response.getRisk();
        double value = mlModelService.predictTaskValue(hours, difficulty, risk);
        return (int) Math.max(1, Math.round(value));
    }

    private String verdictFor(int fairnessPercent) {
        if (fairnessPercent >= 90) {
            return "Çok adil";
        }
        if (fairnessPercent >= 70) {
            return "Kabul edilebilir";
        }
        return "Dengesiz";
    }

    private String suggestionFor(int fairnessPercent, int tokenSuggested) {
        if (fairnessPercent >= 90) {
            return "Takas oldukça adil görünüyor.";
        }
        return String.format(
                "Bu takas %d adil. Dengelemek için yaklaşık %d token önerilir veya ek küçük bir hizmet ekleyebilirsiniz.",
                fairnessPercent,
                tokenSuggested
        );
    }
}
