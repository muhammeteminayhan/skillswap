package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class CreditBalanceDto {
    private Long userId;
    private Integer balance;
    private Integer pricePerCredit;
    private Double platformFeeRate;
}
