package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.CreditRuleEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CreditRuleRepository extends JpaRepository<CreditRuleEntity, Long> {
    Optional<CreditRuleEntity> findByCategory(String category);
}
