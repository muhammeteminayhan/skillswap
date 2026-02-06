package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.ChatMessageDto;
import com.skillswap.backend.backend.dto.ConversationSummaryDto;
import com.skillswap.backend.backend.dto.SendMessageRequest;
import com.skillswap.backend.backend.model.ChatMessageEntity;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.ChatMessageRepository;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class MessagingService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd.MM HH:mm");

    private final ChatMessageRepository chatMessageRepository;
    private final UserProfileRepository userProfileRepository;

    public MessagingService(ChatMessageRepository chatMessageRepository, UserProfileRepository userProfileRepository) {
        this.chatMessageRepository = chatMessageRepository;
        this.userProfileRepository = userProfileRepository;
    }

    public List<ConversationSummaryDto> conversations(Long userId) {
        List<ChatMessageEntity> all = chatMessageRepository
                .findBySenderUserIdOrReceiverUserIdOrderByCreatedAtDesc(userId, userId);

        Map<Long, ConversationSummaryDto> map = new LinkedHashMap<>();
        for (ChatMessageEntity message : all) {
            Long otherId = message.getSenderUserId().equals(userId) ? message.getReceiverUserId() : message.getSenderUserId();
            if (map.containsKey(otherId)) {
                continue;
            }

            ConversationSummaryDto dto = new ConversationSummaryDto();
            dto.setOtherUserId(otherId);
            dto.setLastMessage(message.getBody());
            dto.setLastAt(message.getCreatedAt().format(DATE_FORMATTER));
            dto.setUnreadCount(countUnread(userId, otherId));

            UserProfileEntity other = userProfileRepository.findById(otherId).orElse(null);
            dto.setOtherName(other == null ? "Kullanici" : other.getName());
            dto.setOtherPhotoUrl(other == null ? null : other.getPhotoUrl());
            map.put(otherId, dto);
        }

        return new ArrayList<>(map.values());
    }

    @Transactional
    public List<ChatMessageDto> thread(Long userId, Long otherUserId) {
        List<ChatMessageEntity> messages = chatMessageRepository
                .findBySenderUserIdAndReceiverUserIdOrSenderUserIdAndReceiverUserIdOrderByCreatedAtAsc(
                        userId,
                        otherUserId,
                        otherUserId,
                        userId
                );

        List<ChatMessageEntity> unread = chatMessageRepository
                .findBySenderUserIdAndReceiverUserIdAndReadFalse(otherUserId, userId);
        for (ChatMessageEntity item : unread) {
            item.setRead(true);
        }
        if (!unread.isEmpty()) {
            chatMessageRepository.saveAll(unread);
        }

        return messages.stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional
    public ChatMessageDto send(SendMessageRequest request) {
        if (request.getFromUserId().equals(request.getToUserId())) {
            throw new IllegalArgumentException("Kendine mesaj gonderemezsin.");
        }
        UserProfileEntity from = userProfileRepository.findById(request.getFromUserId())
                .orElseThrow(() -> new IllegalArgumentException("Gonderen kullanici bulunamadi."));
        userProfileRepository.findById(request.getToUserId())
                .orElseThrow(() -> new IllegalArgumentException("Alici kullanici bulunamadi."));

        ChatMessageEntity entity = new ChatMessageEntity();
        entity.setSenderUserId(from.getId());
        entity.setReceiverUserId(request.getToUserId());
        entity.setBody(request.getBody().trim());
        entity.setRead(false);
        return toDto(chatMessageRepository.save(entity));
    }

    private Integer countUnread(Long userId, Long otherUserId) {
        return chatMessageRepository.findBySenderUserIdAndReceiverUserIdAndReadFalse(otherUserId, userId).size();
    }

    private ChatMessageDto toDto(ChatMessageEntity entity) {
        ChatMessageDto dto = new ChatMessageDto();
        dto.setId(entity.getId());
        dto.setSenderUserId(entity.getSenderUserId());
        dto.setReceiverUserId(entity.getReceiverUserId());
        dto.setBody(entity.getBody());
        dto.setCreatedAt(entity.getCreatedAt().format(DATE_FORMATTER));
        dto.setRead(entity.getRead());
        return dto;
    }
}
