package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class BoostResponse {
    private String description;
    private List<BoostPlanDto> plans;
}
