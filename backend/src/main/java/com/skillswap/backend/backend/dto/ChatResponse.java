package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class ChatResponse {
    private String answer;
    private List<MatchSuggestionDto> suggestions;
}
