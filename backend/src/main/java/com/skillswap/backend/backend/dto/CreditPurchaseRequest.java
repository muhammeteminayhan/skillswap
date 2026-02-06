package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class CreditPurchaseRequest {
    private Long userId;
    private Integer credits;
}
