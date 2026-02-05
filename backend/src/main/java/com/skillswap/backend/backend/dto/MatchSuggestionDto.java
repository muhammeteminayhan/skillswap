package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class MatchSuggestionDto {
    private Long userId;
    private String name;
    private String location;
    private Integer trustScore;
    private Integer matchScore;
    private String reason;
}
