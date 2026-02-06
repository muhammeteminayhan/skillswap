package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class CreditTransactionDto {
    private Long id;
    private String type;
    private Integer credits;
    private Integer amountTl;
    private String description;
    private Long matchId;
    private String createdAt;
}
