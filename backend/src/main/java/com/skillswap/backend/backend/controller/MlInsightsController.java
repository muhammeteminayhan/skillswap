package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.MlInsightsResponse;
import com.skillswap.backend.backend.service.MlInsightsService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ml")
public class MlInsightsController {

    private final MlInsightsService mlInsightsService;

    public MlInsightsController(MlInsightsService mlInsightsService) {
        this.mlInsightsService = mlInsightsService;
    }

    @GetMapping("/insights/{userId}")
    public MlInsightsResponse insights(@PathVariable Long userId) {
        return mlInsightsService.buildInsights(userId);
    }
}
