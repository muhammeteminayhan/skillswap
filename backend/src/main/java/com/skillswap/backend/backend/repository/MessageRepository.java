package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.MessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MessageRepository extends JpaRepository<MessageEntity, Long> {
    List<MessageEntity> findByUserIdOrderByCreatedAtDesc(Long userId);

    long countByUserIdAndUnreadTrue(Long userId);

    MessageEntity findTopByUserIdOrderByCreatedAtDesc(Long userId);
}
