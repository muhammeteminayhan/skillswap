package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.CreditRegressionModelEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CreditRegressionModelRepository extends JpaRepository<CreditRegressionModelEntity, Long> {
    Optional<CreditRegressionModelEntity> findTopByOrderByTrainedAtDesc();
}
