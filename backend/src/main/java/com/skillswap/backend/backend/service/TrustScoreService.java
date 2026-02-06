package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TrustScoreService {

    private static final int REVIEW_BASE_POINTS = 3;

    private final UserProfileRepository userProfileRepository;

    public TrustScoreService(UserProfileRepository userProfileRepository) {
        this.userProfileRepository = userProfileRepository;
    }

    @Transactional
    public void applyReview(Long userId, int rating) {
        int delta = REVIEW_BASE_POINTS + ratingDelta(rating);
        applyDelta(userId, delta);
    }

    @Transactional
    public void applySkillAdded(Long userId, int count) {
        if (count <= 0) {
            return;
        }
        applyDelta(userId, count);
    }

    @Transactional
    public void applyProfileFilled(Long userId, int count) {
        if (count <= 0) {
            return;
        }
        applyDelta(userId, count);
    }

    private void applyDelta(Long userId, int delta) {
        if (userId == null || delta == 0) {
            return;
        }
        UserProfileEntity user = userProfileRepository.findById(userId).orElse(null);
        if (user == null) {
            return;
        }
        int current = user.getTrustScore() == null ? 50 : user.getTrustScore();
        int updated = clamp(current + delta, 0, 100);
        user.setTrustScore(updated);
        userProfileRepository.save(user);
    }

    private int ratingDelta(int rating) {
        return switch (rating) {
            case 1 -> -5;
            case 2 -> -2;
            case 3 -> 0;
            case 4 -> 2;
            case 5 -> 5;
            default -> 0;
        };
    }

    private int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }
}
