package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class SwapReviewRequest {
    private Long fromUserId;
    private Integer rating;
    private String comment;
}
