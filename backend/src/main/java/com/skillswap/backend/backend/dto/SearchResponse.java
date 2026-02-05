package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class SearchResponse {
    private String query;
    private Integer radiusKm;
    private List<MatchSuggestionDto> results;
}
