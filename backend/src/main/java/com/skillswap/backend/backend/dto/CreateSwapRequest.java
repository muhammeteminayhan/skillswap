package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class CreateSwapRequest {
    private Long userId;
    private String text;
}
