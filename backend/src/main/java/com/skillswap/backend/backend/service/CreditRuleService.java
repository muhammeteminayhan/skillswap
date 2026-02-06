package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.model.CreditRuleEntity;
import com.skillswap.backend.backend.repository.CreditRuleRepository;
import org.springframework.stereotype.Service;

@Service
public class CreditRuleService {

    private final CreditRuleRepository creditRuleRepository;

    public CreditRuleService(CreditRuleRepository creditRuleRepository) {
        this.creditRuleRepository = creditRuleRepository;
    }

    public CreditRuleEntity getRule(String category) {
        return creditRuleRepository.findByCategory(category)
                .orElseGet(this::defaultRule);
    }

    private CreditRuleEntity defaultRule() {
        CreditRuleEntity rule = new CreditRuleEntity();
        rule.setCategory("DEFAULT");
        rule.setBaseCredit(70);
        rule.setMinCredit(50);
        rule.setMaxCredit(120);
        return rule;
    }
}
