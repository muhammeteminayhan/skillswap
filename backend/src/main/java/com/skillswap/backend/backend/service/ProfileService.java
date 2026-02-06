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

    public ProfileService(UserProfileRepository userProfileRepository, MessageRepository messageRepository) {
        this.userProfileRepository = userProfileRepository;
        this.messageRepository = messageRepository;
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
        entity.setName(clean(request.getName()));
        entity.setTitle(clean(request.getTitle()));
        entity.setLocation(clean(request.getLocation()));
        entity.setBio(cleanNullable(request.getBio()));
        entity.setPhotoUrl(cleanNullable(request.getPhotoUrl()));
        userProfileRepository.save(entity);
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

    private UserProfileEntity fallbackProfile() {
        UserProfileEntity fallback = new UserProfileEntity();
        fallback.setId(1L);
        fallback.setName("Kullanıcı");
        fallback.setTitle("Yetenek Takas Üyesi");
        fallback.setLocation("İstanbul");
        fallback.setTrustScore(75);
        fallback.setPhotoUrl("https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80");
        fallback.setBio("Profil bulunamadı, varsayılan bilgiler gösteriliyor.");
        return fallback;
    }
}
