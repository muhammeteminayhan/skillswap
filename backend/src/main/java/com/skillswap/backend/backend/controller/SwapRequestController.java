package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.CreateSwapRequest;
import com.skillswap.backend.backend.dto.SwapFeedbackRequest;
import com.skillswap.backend.backend.dto.SwapRequestDto;
import com.skillswap.backend.backend.dto.SwapStatusRequest;
import com.skillswap.backend.backend.service.FeedbackService;
import com.skillswap.backend.backend.service.SwapRequestService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/requests")
public class SwapRequestController {

    private final SwapRequestService swapRequestService;
    private final FeedbackService feedbackService;

    public SwapRequestController(SwapRequestService swapRequestService, FeedbackService feedbackService) {
        this.swapRequestService = swapRequestService;
        this.feedbackService = feedbackService;
    }

    @GetMapping("/{userId}")
    public List<SwapRequestDto> list(@PathVariable Long userId) {
        return swapRequestService.list(userId);
    }

    @GetMapping("/{userId}/wants")
    public List<String> listWants(@PathVariable Long userId) {
        return swapRequestService.listWants(userId);
    }

    @GetMapping
    public List<SwapRequestDto> listAll() {
        return swapRequestService.listAll();
    }

    @PostMapping
    public SwapRequestDto create(@RequestBody CreateSwapRequest request) {
        return swapRequestService.create(request);
    }

    @PostMapping("/{userId}/wants")
    public void addWant(@PathVariable Long userId, @RequestBody String want) {
        swapRequestService.addWant(userId, want);
    }

    @DeleteMapping("/{userId}/wants")
    public void deleteWant(@PathVariable Long userId, @RequestParam String want) {
        swapRequestService.deleteWant(userId, want);
    }

    @PostMapping("/{requestId}/feedback")
    public void feedback(@PathVariable Long requestId, @RequestBody SwapFeedbackRequest request) {
        boolean success = request != null && Boolean.TRUE.equals(request.getSuccess());
        feedbackService.record(success);
    }

    @PutMapping("/{requestId}/status")
    public SwapRequestDto updateStatus(
            @PathVariable Long requestId,
            @RequestBody SwapStatusRequest request
    ) {
        return swapRequestService.updateStatus(requestId, request == null ? null : request.getStatus());
    }
}
