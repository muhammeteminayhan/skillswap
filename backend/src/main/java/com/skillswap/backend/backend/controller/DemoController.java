package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.BoostResponse;
import com.skillswap.backend.backend.dto.ChainsResponse;
import com.skillswap.backend.backend.dto.DashboardResponse;
import com.skillswap.backend.backend.dto.QuantumResponse;
import com.skillswap.backend.backend.dto.SearchResponse;
import com.skillswap.backend.backend.dto.TalentResponse;
import com.skillswap.backend.backend.service.DemoShowcaseService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/demo")
public class DemoController {

    private final DemoShowcaseService demoShowcaseService;

    public DemoController(DemoShowcaseService demoShowcaseService) {
        this.demoShowcaseService = demoShowcaseService;
    }

    @GetMapping("/dashboard/{userId}")
    public DashboardResponse dashboard(@PathVariable Long userId) {
        return demoShowcaseService.dashboard(userId);
    }

    @GetMapping("/chains/{userId}")
    public ChainsResponse chains(@PathVariable Long userId) {
        return demoShowcaseService.chains(userId);
    }

    @GetMapping("/quantum/{userId}")
    public QuantumResponse quantum(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "true") boolean realMatching
    ) {
        return demoShowcaseService.quantum(userId, realMatching);
    }

    @GetMapping("/talents/{userId}")
    public TalentResponse talents(@PathVariable Long userId) {
        return demoShowcaseService.talents(userId);
    }

    @GetMapping("/search/{userId}")
    public SearchResponse search(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "") String query,
            @RequestParam(defaultValue = "5") Integer radiusKm
    ) {
        return demoShowcaseService.search(userId, query, radiusKm);
    }

    @GetMapping("/boost")
    public BoostResponse boost() {
        return demoShowcaseService.boost();
    }
}
