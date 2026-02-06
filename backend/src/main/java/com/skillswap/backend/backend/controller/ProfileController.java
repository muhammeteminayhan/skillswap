package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.MessageDto;
import com.skillswap.backend.backend.dto.ProfileResponse;
import com.skillswap.backend.backend.dto.ProfileUpdateRequest;
import com.skillswap.backend.backend.service.ProfileService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping("/profile/{userId}")
    public ProfileResponse profile(@PathVariable Long userId) {
        return profileService.getProfile(userId);
    }

    @PutMapping("/profile/{userId}")
    public ProfileResponse update(@PathVariable Long userId, @Valid @RequestBody ProfileUpdateRequest request) {
        return profileService.updateProfile(userId, request);
    }

    @GetMapping("/messages/{userId}")
    public List<MessageDto> messages(@PathVariable Long userId) {
        return profileService.listMessages(userId);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgument(IllegalArgumentException exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("message", exception.getMessage()));
    }
}
