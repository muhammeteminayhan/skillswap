package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class DashboardResponse {
    private String welcomeText;
    private String userName;
    private Integer reputation;
    private Integer swapCount;
    private List<StatCardDto> quickStats;
    private List<HighlightCardDto> highlights;
}
