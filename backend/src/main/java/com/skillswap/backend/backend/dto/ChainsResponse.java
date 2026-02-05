package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class ChainsResponse {
    private Integer availableChains;
    private Integer activeChains;
    private List<String> chainTips;
}
