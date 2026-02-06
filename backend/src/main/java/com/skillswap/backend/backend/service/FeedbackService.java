package com.skillswap.backend.backend.service;

import org.springframework.stereotype.Service;

import java.util.concurrent.atomic.AtomicInteger;

@Service
public class FeedbackService {

    private final AtomicInteger successCount = new AtomicInteger(0);
    private final AtomicInteger failureCount = new AtomicInteger(0);

    public void record(boolean success) {
        if (success) {
            successCount.incrementAndGet();
        } else {
            failureCount.incrementAndGet();
        }
    }

    public double feedbackMultiplier() {
        int success = successCount.get();
        int failure = failureCount.get();
        int delta = success - failure;
        double raw = 1.0 + (delta * 0.01);
        if (raw < 0.85) {
            return 0.85;
        }
        if (raw > 1.15) {
            return 1.15;
        }
        return raw;
    }
}
