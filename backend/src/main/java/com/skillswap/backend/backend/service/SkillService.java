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
    private final SwapRequestService swapRequestService;
    private final TrustScoreService trustScoreService;

    public SkillService(
            UserSkillRepository userSkillRepository,
            SwapRequestService swapRequestService,
            TrustScoreService trustScoreService
    ) {
        this.userSkillRepository = userSkillRepository;
        this.swapRequestService = swapRequestService;
        this.trustScoreService = trustScoreService;
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
        int beforeCount = userSkillRepository.findByUserId(userId).size();
        userSkillRepository.deleteByUserId(userId);
        int addedCount = 0;

        if (request != null && request.getOffers() != null) {
            for (SkillItemDto offer : request.getOffers()) {
                if (offer != null && offer.getName() != null && !offer.getName().isBlank()) {
                    save(
                            userId,
                            offer.getName(),
                            cleanDescription(offer.getDescription()),
                            "OFFER"
                    );
                    addedCount++;
                }
            }
        }

        if (request != null && request.getWants() != null) {
            for (SkillItemDto want : request.getWants()) {
                if (want != null && want.getName() != null && !want.getName().isBlank()) {
                    save(
                            userId,
                            want.getName(),
                            cleanDescription(want.getDescription()),
                            "WANT"
                    );
                    addedCount++;
                }
            }
        }

        SkillsResponse response = getSkills(userId);
        swapRequestService.rebuildForUser(userId);
        int delta = Math.max(0, addedCount - beforeCount);
        trustScoreService.applySkillAdded(userId, delta);
        return response;
    }

    @Transactional
    public SkillItemDto addOfferSkill(Long userId, SkillItemDto request) {
        if (request == null || request.getName() == null || request.getName().isBlank()) {
            throw new IllegalArgumentException("Yetenek adi zorunludur.");
        }

        String rawName = request.getName().trim();
        String normalizedName = normalizeSkillName(rawName);
        boolean duplicate = userSkillRepository.existsByUserIdAndSkillTypeAndNormalizedSkill(
                userId,
                "OFFER",
                normalizedName
        );
        if (duplicate) {
            throw new IllegalArgumentException("Ayni adda bir yetenek zaten mevcut.");
        }

        UserSkillEntity entity = save(userId, rawName, cleanDescription(request.getDescription()), "OFFER");
        swapRequestService.rebuildForUser(userId);
        trustScoreService.applySkillAdded(userId, 1);
        return toDto(entity);
    }

    @Transactional
    public SkillItemDto updateOfferSkill(Long userId, Long skillId, SkillItemDto request) {
        UserSkillEntity entity = userSkillRepository.findById(skillId)
                .orElseThrow(() -> new IllegalArgumentException("Yetenek bulunamadi."));
        if (!entity.getUserId().equals(userId) || !"OFFER".equals(entity.getSkillType())) {
            throw new IllegalArgumentException("Bu yetenegi guncelleyemezsiniz.");
        }
        String rawName = request == null || request.getName() == null ? "" : request.getName().trim();
        if (rawName.isBlank()) {
            throw new IllegalArgumentException("Yetenek adi zorunludur.");
        }
        String normalizedName = normalizeSkillName(rawName);

        boolean duplicate = userSkillRepository.existsByUserIdAndSkillTypeAndNormalizedSkill(
                userId,
                "OFFER",
                normalizedName
        );
        if (duplicate && !entity.getNormalizedSkill().equalsIgnoreCase(normalizedName)) {
            throw new IllegalArgumentException("Ayni adda bir yetenek zaten mevcut.");
        }

        entity.setSkillName(rawName);
        entity.setNormalizedSkill(normalizedName);
        entity.setSkillDescription(cleanDescription(request.getDescription()));
        swapRequestService.rebuildForUser(userId);
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
        swapRequestService.rebuildForUser(userId);
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
        return SkillNormalizer.normalize(raw);
    }

    private UserSkillEntity save(Long userId, String skillName, String description, String type) {
        UserSkillEntity entity = new UserSkillEntity();
        entity.setUserId(userId);
        entity.setSkillName(skillName.trim());
        entity.setNormalizedSkill(SkillNormalizer.normalize(skillName));
        entity.setSkillDescription(description);
        entity.setSkillType(type);
        return userSkillRepository.save(entity);
    }
}
