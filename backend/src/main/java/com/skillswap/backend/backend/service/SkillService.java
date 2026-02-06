package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.SkillItemDto;
import com.skillswap.backend.backend.dto.SkillsResponse;
import com.skillswap.backend.backend.dto.SkillsUpdateRequest;
import com.skillswap.backend.backend.model.UserSkillEntity;
import com.skillswap.backend.backend.repository.UserSkillRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class SkillService {

    private final UserSkillRepository userSkillRepository;

    public SkillService(UserSkillRepository userSkillRepository) {
        this.userSkillRepository = userSkillRepository;
    }

    public SkillsResponse getSkills(Long userId) {
        List<UserSkillEntity> skills = userSkillRepository.findByUserId(userId);
        List<SkillItemDto> offers = new ArrayList<>();
        List<SkillItemDto> wants = new ArrayList<>();

        for (UserSkillEntity skill : skills) {
            if ("OFFER".equals(skill.getSkillType())) {
                offers.add(toDto(skill));
            } else if ("WANT".equals(skill.getSkillType())) {
                wants.add(toDto(skill));
            }
        }

        SkillsResponse response = new SkillsResponse();
        response.setUserId(userId);
        response.setOffers(offers);
        response.setWants(wants);
        return response;
    }

    @Transactional
    public SkillsResponse updateSkills(Long userId, SkillsUpdateRequest request) {
        userSkillRepository.deleteByUserId(userId);

        if (request != null && request.getOffers() != null) {
            for (SkillItemDto offer : request.getOffers()) {
                if (offer != null && offer.getName() != null && !offer.getName().isBlank()) {
                    save(
                            userId,
                            normalizeSkillName(offer.getName()),
                            cleanDescription(offer.getDescription()),
                            "OFFER"
                    );
                }
            }
        }

        if (request != null && request.getWants() != null) {
            for (SkillItemDto want : request.getWants()) {
                if (want != null && want.getName() != null && !want.getName().isBlank()) {
                    save(
                            userId,
                            normalizeSkillName(want.getName()),
                            cleanDescription(want.getDescription()),
                            "WANT"
                    );
                }
            }
        }

        return getSkills(userId);
    }

    @Transactional
    public SkillItemDto addOfferSkill(Long userId, SkillItemDto request) {
        if (request == null || request.getName() == null || request.getName().isBlank()) {
            throw new IllegalArgumentException("Yetenek adi zorunludur.");
        }

        String normalizedName = normalizeSkillName(request.getName());
        boolean duplicate = userSkillRepository.existsByUserIdAndSkillTypeAndSkillNameIgnoreCase(
                userId,
                "OFFER",
                normalizedName
        );
        if (duplicate) {
            throw new IllegalArgumentException("Ayni adda bir yetenek zaten mevcut.");
        }

        UserSkillEntity entity = save(userId, normalizedName, cleanDescription(request.getDescription()), "OFFER");
        return toDto(entity);
    }

    @Transactional
    public SkillItemDto updateOfferSkill(Long userId, Long skillId, SkillItemDto request) {
        UserSkillEntity entity = userSkillRepository.findById(skillId)
                .orElseThrow(() -> new IllegalArgumentException("Yetenek bulunamadi."));
        if (!entity.getUserId().equals(userId) || !"OFFER".equals(entity.getSkillType())) {
            throw new IllegalArgumentException("Bu yetenegi guncelleyemezsiniz.");
        }
        String name = request == null || request.getName() == null ? "" : normalizeSkillName(request.getName());
        if (name.isBlank()) {
            throw new IllegalArgumentException("Yetenek adi zorunludur.");
        }

        boolean duplicate = userSkillRepository.existsByUserIdAndSkillTypeAndSkillNameIgnoreCase(
                userId,
                "OFFER",
                name
        );
        if (duplicate && !entity.getSkillName().equalsIgnoreCase(name)) {
            throw new IllegalArgumentException("Ayni adda bir yetenek zaten mevcut.");
        }

        entity.setSkillName(name);
        entity.setSkillDescription(cleanDescription(request.getDescription()));
        return toDto(userSkillRepository.save(entity));
    }

    @Transactional
    public void deleteOfferSkill(Long userId, Long skillId) {
        UserSkillEntity entity = userSkillRepository.findById(skillId)
                .orElseThrow(() -> new IllegalArgumentException("Yetenek bulunamadi."));
        if (!entity.getUserId().equals(userId) || !"OFFER".equals(entity.getSkillType())) {
            throw new IllegalArgumentException("Bu yetenegi silemezsiniz.");
        }
        userSkillRepository.delete(entity);
    }

    private SkillItemDto toDto(UserSkillEntity entity) {
        SkillItemDto dto = new SkillItemDto();
        dto.setId(entity.getId());
        dto.setName(entity.getSkillName());
        dto.setDescription(entity.getSkillDescription());
        return dto;
    }

    private String cleanDescription(String description) {
        if (description == null) {
            return "";
        }
        return description.trim();
    }

    private String normalizeSkillName(String raw) {
        if (raw == null) {
            return "";
        }
        String trimmed = raw.trim();
        if (trimmed.isEmpty()) {
            return "";
        }
        String lower = trimmed.toLowerCase(java.util.Locale.forLanguageTag("tr"));
        if (lower.contains("tesisat")) {
            return "Tesisat";
        }
        if (lower.contains("elektrik")) {
            return "Elektrik";
        }
        if (lower.contains("boya") || lower.contains("badana")) {
            return "Boya";
        }
        if (lower.contains("dogalgaz") || lower.contains("doğalgaz")) {
            return "Dogalgaz";
        }
        if (lower.contains("kombi")) {
            return "Kombi";
        }
        if (lower.contains("bilgisayar") || lower.contains("pc")) {
            return "Bilgisayar Teknik";
        }
        if (lower.contains("temizlik")) {
            return "Temizlik";
        }
        return trimmed.substring(0, 1).toUpperCase() + trimmed.substring(1).toLowerCase();
    }

    private UserSkillEntity save(Long userId, String skillName, String description, String type) {
        UserSkillEntity entity = new UserSkillEntity();
        entity.setUserId(userId);
        entity.setSkillName(skillName);
        entity.setSkillDescription(description);
        entity.setSkillType(type);
        return userSkillRepository.save(entity);
    }
}
