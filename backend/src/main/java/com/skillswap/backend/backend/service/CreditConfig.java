package com.skillswap.backend.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class CreditConfig {

    @Value("${app.credit.pricePerCredit:50}")
    private int pricePerCredit;

    @Value("${app.credit.platformFeeRate:0.1}")
    private double platformFeeRate;

    @Value("${app.credit.regression.enabled:true}")
    private boolean regressionEnabled;

    @Value("${app.credit.regression.intercept:29.055288}")
    private double regressionIntercept;

    @Value("${app.credit.regression.hours:2.739208}")
    private double regressionHours;

    @Value("${app.credit.regression.difficulty:5.531295}")
    private double regressionDifficulty;

    @Value("${app.credit.regression.risk:3.573124}")
    private double regressionRisk;

    @Value("${app.credit.regression.scope:7.220236}")
    private double regressionScope;

    @Value("${app.credit.regression.trust:0.089568}")
    private double regressionTrust;

    @Value("${app.credit.regression.min:50}")
    private int regressionMin;

    @Value("${app.credit.regression.max:150}")
    private int regressionMax;

    public int getPricePerCredit() {
        return pricePerCredit;
    }

    public double getPlatformFeeRate() {
        return platformFeeRate;
    }

    public boolean isRegressionEnabled() {
        return regressionEnabled;
    }

    public double getRegressionIntercept() {
        return regressionIntercept;
    }

    public double getRegressionHours() {
        return regressionHours;
    }

    public double getRegressionDifficulty() {
        return regressionDifficulty;
    }

    public double getRegressionRisk() {
        return regressionRisk;
    }

    public double getRegressionScope() {
        return regressionScope;
    }

    public double getRegressionTrust() {
        return regressionTrust;
    }

    public int getRegressionMin() {
        return regressionMin;
    }

    public int getRegressionMax() {
        return regressionMax;
    }
}
