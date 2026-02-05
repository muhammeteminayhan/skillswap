package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class SkillsUpdateRequest {
    private List<SkillItemDto> offers;
    private List<SkillItemDto> wants;
}
