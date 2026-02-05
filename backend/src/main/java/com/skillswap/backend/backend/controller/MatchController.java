package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.MatchRequest;
import com.skillswap.backend.backend.dto.MatchResponse;
import com.skillswap.backend.backend.service.MatchService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MatchController {

    private final MatchService matchService;

    public MatchController(MatchService matchService) {
        this.matchService = matchService;
    }

    @PostMapping("/match")
    public MatchResponse match(@RequestBody MatchRequest request) {
        String text = request == null ? "" : request.getText();
        return matchService.match(text);
    }
}
