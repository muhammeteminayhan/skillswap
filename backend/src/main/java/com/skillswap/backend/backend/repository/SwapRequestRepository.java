package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.SwapRequestEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SwapRequestRepository extends JpaRepository<SwapRequestEntity, Long> {
    List<SwapRequestEntity> findByUserIdOrderByCreatedAtDesc(Long userId);
}
