package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.CreditProfileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CreditProfileRepository extends JpaRepository<CreditProfileEntity, String> {
    Optional<CreditProfileEntity> findByCategory(String category);
}
