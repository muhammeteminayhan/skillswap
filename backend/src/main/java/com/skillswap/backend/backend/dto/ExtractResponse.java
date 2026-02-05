package com.skillswap.backend.backend.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import java.util.List;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class ExtractResponse {
    private List<String> wants;
    private List<String> offers;
    private String urgency;
    private Double estimatedTimeHours;
    private Integer difficulty;
    private Integer risk;
    private String locationHint;
}
