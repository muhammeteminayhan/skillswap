package com.skillswap.backend.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class SendMessageRequest {

    @NotNull
    private Long fromUserId;

    @NotNull
    private Long toUserId;

    @NotBlank
    private String body;
}
