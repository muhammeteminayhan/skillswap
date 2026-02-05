package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.MessageDto;
import com.skillswap.backend.backend.dto.ProfileResponse;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProfileService {

    private final UserProfileRepository userProfileRepository;

    public ProfileService(UserProfileRepository userProfileRepository) {
        this.userProfileRepository = userProfileRepository;
    }

    public ProfileResponse getProfile(Long userId) {
        UserProfileEntity entity = userProfileRepository.findById(userId).orElseGet(this::fallbackProfile);
        ProfileResponse response = new ProfileResponse();
        response.setUserId(entity.getId());
        response.setName(entity.getName());
        response.setTitle(entity.getTitle());
        response.setLocation(entity.getLocation());
        response.setTrustScore(entity.getTrustScore());
        response.setBio(entity.getBio());
        return response;
    }

    public List<MessageDto> listMessages(Long userId) {
        return List.of(
                message("Tuncay", "Merhaba, cumartesi tesisat işine uygunum.", "10:45", true),
                message("Merve", "Kombi bakımı için bu akşam müsaitim.", "Dün", false),
                message("Selin", "Laptop format desteği karşılığında priz işini konuşalım.", "Dün", false)
        );
    }

    private MessageDto message(String from, String preview, String time, boolean unread) {
        MessageDto dto = new MessageDto();
        dto.setFrom(from);
        dto.setPreview(preview);
        dto.setTime(time);
        dto.setUnread(unread);
        return dto;
    }

    private UserProfileEntity fallbackProfile() {
        UserProfileEntity fallback = new UserProfileEntity();
        fallback.setId(1L);
        fallback.setName("Kullanıcı");
        fallback.setTitle("Yetenek Takas Üyesi");
        fallback.setLocation("İstanbul");
        fallback.setTrustScore(75);
        fallback.setBio("Profil bulunamadı, varsayılan bilgiler gösteriliyor.");
        return fallback;
    }
}
