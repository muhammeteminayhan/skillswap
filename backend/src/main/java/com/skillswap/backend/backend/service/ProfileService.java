package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.MessageDto;
import com.skillswap.backend.backend.dto.ProfileResponse;
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
        response.setTokenBalance(entity.getTokenBalance() == null ? 0 : entity.getTokenBalance());
        response.setBio(entity.getBio());
        return response;
    }

    public List<MessageDto> listMessages(Long userId) {
        return messageRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::fromEntity)
                .toList();
    }

    private MessageDto fromEntity(MessageEntity entity) {
        MessageDto dto = new MessageDto();
        dto.setFrom(entity.getFromName());
        dto.setPreview(entity.getPreview());
        dto.setTime(entity.getTimeLabel());
        dto.setUnread(Boolean.TRUE.equals(entity.getUnread()));
        return dto;
    }

    private UserProfileEntity fallbackProfile() {
        UserProfileEntity fallback = new UserProfileEntity();
        fallback.setId(1L);
        fallback.setName("Kullanıcı");
        fallback.setTitle("Yetenek Takas Üyesi");
        fallback.setLocation("İstanbul");
        fallback.setTrustScore(75);
        fallback.setTokenBalance(1000);
        fallback.setBio("Profil bulunamadı, varsayılan bilgiler gösteriliyor.");
        return fallback;
    }
}
