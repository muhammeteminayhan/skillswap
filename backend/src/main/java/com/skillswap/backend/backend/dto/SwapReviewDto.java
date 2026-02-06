package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class SwapReviewDto {
    private Long id;
    private Long matchId;
    private Long fromUserId;
    private String fromName;
    private Long toUserId;
    private Integer rating;
    private String comment;
    private String createdAt;
}
