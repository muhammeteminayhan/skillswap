package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class SkillsResponse {
    private Long userId;
    private List<SkillItemDto> offers;
    private List<SkillItemDto> wants;
}
