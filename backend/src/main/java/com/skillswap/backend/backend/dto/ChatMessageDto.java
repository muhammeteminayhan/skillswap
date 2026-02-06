package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class ChatMessageDto {

    private Long id;
    private Long senderUserId;
    private Long receiverUserId;
    private String body;
    private String createdAt;
    private Boolean read;
}
