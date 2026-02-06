package com.skillswap.backend.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class CreditConfig {

    @Value("${app.credit.pricePerCredit:50}")
    private int pricePerCredit;

    @Value("${app.credit.platformFeeRate:0.1}")
    private double platformFeeRate;

    public int getPricePerCredit() {
        return pricePerCredit;
    }

    public double getPlatformFeeRate() {
        return platformFeeRate;
    }
}
