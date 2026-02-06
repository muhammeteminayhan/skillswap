package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.ChatMessageEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChatMessageRepository extends JpaRepository<ChatMessageEntity, Long> {

    List<ChatMessageEntity> findBySenderUserIdOrReceiverUserIdOrderByCreatedAtDesc(Long senderUserId, Long receiverUserId);

    List<ChatMessageEntity> findBySenderUserIdAndReceiverUserIdOrSenderUserIdAndReceiverUserIdOrderByCreatedAtAsc(
            Long senderUserId,
            Long receiverUserId,
            Long senderUserId2,
            Long receiverUserId2
    );

    List<ChatMessageEntity> findBySenderUserIdAndReceiverUserIdAndReadFalse(Long senderUserId, Long receiverUserId);
}
