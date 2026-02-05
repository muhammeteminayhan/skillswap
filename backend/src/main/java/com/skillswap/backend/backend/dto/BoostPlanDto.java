package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class BoostPlanDto {
    private String title;
    private String price;
    private List<String> benefits;
}
