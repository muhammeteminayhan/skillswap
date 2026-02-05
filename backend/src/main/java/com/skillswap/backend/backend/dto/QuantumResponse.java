package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class QuantumResponse {
    private Boolean realMatching;
    private String quantumState;
    private Integer entanglements;
    private List<QuantumMatchDto> matches;
}
