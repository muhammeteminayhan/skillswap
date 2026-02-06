package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.SwapMatchEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SwapMatchRepository extends JpaRepository<SwapMatchEntity, Long> {
    List<SwapMatchEntity> findByUserAIdOrUserBIdOrderByUpdatedAtDesc(Long userAId, Long userBId);

    boolean existsByRequestAIdAndRequestBId(Long requestAId, Long requestBId);
}
