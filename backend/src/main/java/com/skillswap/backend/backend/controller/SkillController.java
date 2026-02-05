package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.SkillsResponse;
import com.skillswap.backend.backend.dto.SkillsUpdateRequest;
import com.skillswap.backend.backend.service.SkillService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/skills")
public class SkillController {

    private final SkillService skillService;

    public SkillController(SkillService skillService) {
        this.skillService = skillService;
    }

    @GetMapping("/{userId}")
    public SkillsResponse getSkills(@PathVariable Long userId) {
        return skillService.getSkills(userId);
    }

    @PutMapping("/{userId}")
    public SkillsResponse updateSkills(@PathVariable Long userId, @RequestBody SkillsUpdateRequest request) {
        return skillService.updateSkills(userId, request);
    }
}
