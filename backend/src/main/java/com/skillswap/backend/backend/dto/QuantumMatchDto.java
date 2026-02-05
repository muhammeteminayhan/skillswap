package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class QuantumMatchDto {
    private Long userId;
    private String name;
    private String title;
    private Integer probability;
    private List<String> tags;
    private String reason;
}
