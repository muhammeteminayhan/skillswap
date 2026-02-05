package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.MessageDto;
import com.skillswap.backend.backend.dto.ProfileResponse;
import com.skillswap.backend.backend.service.ProfileService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

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

    @GetMapping("/messages/{userId}")
    public List<MessageDto> messages(@PathVariable Long userId) {
        return profileService.listMessages(userId);
    }
}
