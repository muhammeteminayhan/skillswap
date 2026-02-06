package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.SkillItemDto;
import com.skillswap.backend.backend.dto.SkillsResponse;
import com.skillswap.backend.backend.dto.SkillsUpdateRequest;
import com.skillswap.backend.backend.service.SkillService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.Map;

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

    @PostMapping("/{userId}/offer")
    public SkillItemDto addOffer(@PathVariable Long userId, @RequestBody SkillItemDto request) {
        return skillService.addOfferSkill(userId, request);
    }

    @PutMapping("/{userId}/offer/{skillId}")
    public SkillItemDto updateOffer(
            @PathVariable Long userId,
            @PathVariable Long skillId,
            @RequestBody SkillItemDto request
    ) {
        return skillService.updateOfferSkill(userId, skillId, request);
    }

    @DeleteMapping("/{userId}/offer/{skillId}")
    public ResponseEntity<Void> deleteOffer(
            @PathVariable Long userId,
            @PathVariable Long skillId
    ) {
        skillService.deleteOfferSkill(userId, skillId);
        return ResponseEntity.noContent().build();
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgument(IllegalArgumentException exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("message", exception.getMessage()));
    }
}
