package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.model.CreditRuleEntity;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;

import java.util.Locale;

@Service
public class CreditValuationService {

    private static final double MAX_TRUST_BONUS = 0.08;

    private final CreditRuleService creditRuleService;
    private final UserProfileRepository userProfileRepository;

    public CreditValuationService(
            CreditRuleService creditRuleService,
            UserProfileRepository userProfileRepository
    ) {
        this.creditRuleService = creditRuleService;
        this.userProfileRepository = userProfileRepository;
    }

    public int evaluate(Long userId, String offeredSkill) {
        String category = SkillNormalizer.normalize(offeredSkill);
        CreditRuleEntity rule = creditRuleService.getRule(category);
        int base = rule.getBaseCredit();
        double scopeMultiplier = scopeMultiplier(offeredSkill);
        double trustMultiplier = trustMultiplier(userId);
        int credit = (int) Math.round(base * scopeMultiplier * trustMultiplier);
        if (credit < rule.getMinCredit()) {
            credit = rule.getMinCredit();
        }
        if (credit > rule.getMaxCredit()) {
            credit = rule.getMaxCredit();
        }
        return credit;
    }

    private double trustMultiplier(Long userId) {
        if (userId == null) {
            return 1.0;
        }
        UserProfileEntity profile = userProfileRepository.findById(userId).orElse(null);
        if (profile == null || profile.getTrustScore() == null) {
            return 1.0;
        }
        double trust = Math.max(0, Math.min(100, profile.getTrustScore()));
        return 1.0 + (trust / 100.0) * MAX_TRUST_BONUS;
    }

    private double scopeMultiplier(String text) {
        if (text == null) {
            return 1.0;
        }
        String lower = text.toLowerCase(Locale.forLanguageTag("tr"));
        if (lower.contains("kapsamli") || lower.contains("kapsamlı")
                || lower.contains("komple") || lower.contains("full")
                || lower.contains("profesyonel") || lower.contains("entegre")
                || lower.contains("sistem")) {
            return 1.15;
        }
        if (lower.contains("basit") || lower.contains("mini") || lower.contains("kucuk")
                || lower.contains("küçük")) {
            return 0.9;
        }
        return 1.0;
    }
}
