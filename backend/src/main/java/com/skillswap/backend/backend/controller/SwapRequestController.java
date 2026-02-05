package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.CreateSwapRequest;
import com.skillswap.backend.backend.dto.SwapRequestDto;
import com.skillswap.backend.backend.service.SwapRequestService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/requests")
public class SwapRequestController {

    private final SwapRequestService swapRequestService;

    public SwapRequestController(SwapRequestService swapRequestService) {
        this.swapRequestService = swapRequestService;
    }

    @GetMapping("/{userId}")
    public List<SwapRequestDto> list(@PathVariable Long userId) {
        return swapRequestService.list(userId);
    }

    @PostMapping
    public SwapRequestDto create(@RequestBody CreateSwapRequest request) {
        return swapRequestService.create(request);
    }
}
