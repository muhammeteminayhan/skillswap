package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class MlInsightsResponse {
    private Long userId;
    private Integer churnRiskPercent;
    private Integer openRequests;
    private Integer unreadMessages;
    private Integer daysInactive;
    private String modelVersion;
    private List<String> actions;
}
