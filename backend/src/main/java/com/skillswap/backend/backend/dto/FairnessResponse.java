package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class FairnessResponse {
    private int fairnessPercent;
    private int leftValue;
    private int rightValue;
    private int deltaValue;
    private int tokenSuggested;
    private String suggestionText;
    private String verdict;
}
