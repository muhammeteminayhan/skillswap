package com.skillswap.backend.backend.service;

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
        List<String> offers = new ArrayList<>();
        List<String> wants = new ArrayList<>();

        for (UserSkillEntity skill : skills) {
            if ("OFFER".equals(skill.getSkillType())) {
                offers.add(skill.getSkillName());
            } else if ("WANT".equals(skill.getSkillType())) {
                wants.add(skill.getSkillName());
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
            for (String offer : request.getOffers()) {
                if (offer != null && !offer.isBlank()) {
                    save(userId, offer.trim(), "OFFER");
                }
            }
        }

        if (request != null && request.getWants() != null) {
            for (String want : request.getWants()) {
                if (want != null && !want.isBlank()) {
                    save(userId, want.trim(), "WANT");
                }
            }
        }

        return getSkills(userId);
    }

    private void save(Long userId, String skillName, String type) {
        UserSkillEntity entity = new UserSkillEntity();
        entity.setUserId(userId);
        entity.setSkillName(skillName);
        entity.setSkillType(type);
        userSkillRepository.save(entity);
    }
}
