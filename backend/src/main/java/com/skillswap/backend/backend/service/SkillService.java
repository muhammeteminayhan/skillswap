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
                    save(userId, offer.getName().trim(), cleanDescription(offer.getDescription()), "OFFER");
                }
            }
        }

        if (request != null && request.getWants() != null) {
            for (SkillItemDto want : request.getWants()) {
                if (want != null && want.getName() != null && !want.getName().isBlank()) {
                    save(userId, want.getName().trim(), cleanDescription(want.getDescription()), "WANT");
                }
            }
        }

        return getSkills(userId);
    }

    private SkillItemDto toDto(UserSkillEntity entity) {
        SkillItemDto dto = new SkillItemDto();
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

    private void save(Long userId, String skillName, String description, String type) {
        UserSkillEntity entity = new UserSkillEntity();
        entity.setUserId(userId);
        entity.setSkillName(skillName);
        entity.setSkillDescription(description);
        entity.setSkillType(type);
        userSkillRepository.save(entity);
    }
}
