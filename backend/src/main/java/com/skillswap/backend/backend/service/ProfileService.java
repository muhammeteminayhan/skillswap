package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.MessageDto;
import com.skillswap.backend.backend.dto.ProfileResponse;
import com.skillswap.backend.backend.dto.ProfileUpdateRequest;
import com.skillswap.backend.backend.model.MessageEntity;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.MessageRepository;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProfileService {

    private final UserProfileRepository userProfileRepository;
    private final MessageRepository messageRepository;
    private final TrustScoreService trustScoreService;

    public ProfileService(
            UserProfileRepository userProfileRepository,
            MessageRepository messageRepository,
            TrustScoreService trustScoreService
    ) {
        this.userProfileRepository = userProfileRepository;
        this.messageRepository = messageRepository;
        this.trustScoreService = trustScoreService;
    }

    public ProfileResponse getProfile(Long userId) {
        UserProfileEntity entity = userProfileRepository.findById(userId).orElseGet(this::fallbackProfile);
        ProfileResponse response = new ProfileResponse();
        response.setUserId(entity.getId());
        response.setName(entity.getName());
        response.setTitle(entity.getTitle());
        response.setLocation(entity.getLocation());
        response.setTrustScore(entity.getTrustScore());
        response.setPhotoUrl(entity.getPhotoUrl());
        response.setBio(entity.getBio());
        return response;
    }

    public List<MessageDto> listMessages(Long userId) {
        return messageRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::fromEntity)
                .toList();
    }

    public ProfileResponse updateProfile(Long userId, ProfileUpdateRequest request) {
        UserProfileEntity entity = userProfileRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Kullanici bulunamadi."));
        String newName = clean(request.getName());
        String newTitle = clean(request.getTitle());
        String newLocation = clean(request.getLocation());
        String newBio = cleanNullable(request.getBio());
        String newPhoto = cleanNullable(request.getPhotoUrl());

        int filledCount = 0;
        if (isBlank(entity.getTitle()) && !isBlank(newTitle)) filledCount++;
        if (isBlank(entity.getLocation()) && !isBlank(newLocation)) filledCount++;
        if (isBlank(entity.getBio()) && !isBlank(newBio)) filledCount++;
        if (isBlank(entity.getPhotoUrl()) && !isBlank(newPhoto)) filledCount++;

        entity.setName(newName);
        entity.setTitle(newTitle);
        entity.setLocation(newLocation);
        entity.setBio(newBio);
        entity.setPhotoUrl(newPhoto);
        userProfileRepository.save(entity);
        trustScoreService.applyProfileFilled(userId, filledCount);
        return getProfile(userId);
    }

    private MessageDto fromEntity(MessageEntity entity) {
        MessageDto dto = new MessageDto();
        dto.setFrom(entity.getFromName());
        dto.setPreview(entity.getPreview());
        dto.setTime(entity.getTimeLabel());
        dto.setUnread(Boolean.TRUE.equals(entity.getUnread()));
        return dto;
    }

    private String clean(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        return value.trim();
    }

    private String cleanNullable(String value) {
        if (value == null) {
            return "";
        }
        return value.trim();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private UserProfileEntity fallbackProfile() {
        UserProfileEntity fallback = new UserProfileEntity();
        fallback.setId(1L);
        fallback.setName("Kullanıcı");
        fallback.setTitle("Yetenek Takas Üyesi");
        fallback.setLocation("İstanbul");
        fallback.setTrustScore(50);
        fallback.setPhotoUrl("https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80");
        fallback.setBio("Profil bulunamadı, varsayılan bilgiler gösteriliyor.");
        return fallback;
    }
}
