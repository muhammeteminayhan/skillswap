package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class TalentResponse {
    private String intro;
    private List<TalentSuggestionDto> talents;
}
