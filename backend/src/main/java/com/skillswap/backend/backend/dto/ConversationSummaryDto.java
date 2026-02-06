package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class ConversationSummaryDto {

    private Long otherUserId;
    private String otherName;
    private String otherPhotoUrl;
    private String lastMessage;
    private String lastAt;
    private Integer unreadCount;
}
