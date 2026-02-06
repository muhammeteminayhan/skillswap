package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.CreditWalletEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CreditWalletRepository extends JpaRepository<CreditWalletEntity, Long> {
    Optional<CreditWalletEntity> findByUserId(Long userId);
}
