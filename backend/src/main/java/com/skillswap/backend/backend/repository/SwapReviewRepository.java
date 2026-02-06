package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.SwapReviewEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SwapReviewRepository extends JpaRepository<SwapReviewEntity, Long> {
    boolean existsByMatchIdAndFromUserId(Long matchId, Long fromUserId);

    java.util.List<SwapReviewEntity> findByMatchIdOrderByCreatedAtDesc(Long matchId);

    java.util.List<SwapReviewEntity> findByToUserIdOrderByCreatedAtDesc(Long toUserId);
}
