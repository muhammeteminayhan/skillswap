package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class TalentSuggestionDto {
    private String title;
    private Integer matchPercent;
    private String description;
}
