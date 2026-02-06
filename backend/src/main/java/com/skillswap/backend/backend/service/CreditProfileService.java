package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.model.CreditProfileEntity;
import com.skillswap.backend.backend.repository.CreditProfileRepository;
import org.springframework.stereotype.Service;

@Service
public class CreditProfileService {

    private final CreditProfileRepository creditProfileRepository;

    public CreditProfileService(CreditProfileRepository creditProfileRepository) {
        this.creditProfileRepository = creditProfileRepository;
    }

    public CreditProfileEntity getProfile(String category) {
        return creditProfileRepository.findByCategory(category)
                .orElseGet(this::defaultProfile);
    }

    private CreditProfileEntity defaultProfile() {
        CreditProfileEntity profile = new CreditProfileEntity();
        profile.setCategory("DEFAULT");
        profile.setHours(6.0);
        profile.setDifficulty(2);
        profile.setRisk(2);
        profile.setScope(1.0);
        return profile;
    }
}
