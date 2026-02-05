package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class SwapRequestDto {
    private Long id;
    private Long userId;
    private String text;
    private String wantedSkill;
    private String offeredSkill;
    private String status;
    private String createdAt;
}
