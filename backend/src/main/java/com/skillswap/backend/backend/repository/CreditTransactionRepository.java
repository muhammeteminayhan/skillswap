package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.CreditTransactionEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CreditTransactionRepository extends JpaRepository<CreditTransactionEntity, Long> {
    List<CreditTransactionEntity> findByUserIdOrderByCreatedAtDesc(Long userId);
}
