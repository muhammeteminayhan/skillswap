package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.SwapAcceptRequest;
import com.skillswap.backend.backend.dto.SwapDoneRequest;
import com.skillswap.backend.backend.dto.SwapMatchDto;
import com.skillswap.backend.backend.dto.SwapRebuildResponse;
import com.skillswap.backend.backend.dto.SwapReviewDto;
import com.skillswap.backend.backend.dto.SwapReviewRequest;
import com.skillswap.backend.backend.service.SwapMatchService;
import com.skillswap.backend.backend.service.SwapReviewService;
import com.skillswap.backend.backend.repository.SwapRequestRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/swaps")
public class SwapMatchController {

    private final SwapMatchService swapMatchService;
    private final SwapReviewService swapReviewService;
    private final SwapRequestRepository swapRequestRepository;

    public SwapMatchController(
            SwapMatchService swapMatchService,
            SwapReviewService swapReviewService,
            SwapRequestRepository swapRequestRepository
    ) {
        this.swapMatchService = swapMatchService;
        this.swapReviewService = swapReviewService;
        this.swapRequestRepository = swapRequestRepository;
    }

    @GetMapping("/matches/{userId}")
    public List<SwapMatchDto> list(@PathVariable Long userId) {
        return swapMatchService.listForUser(userId);
    }

    @PostMapping("/matches/{matchId}/accept")
    public SwapMatchDto accept(@PathVariable Long matchId, @RequestBody SwapAcceptRequest request) {
        return swapMatchService.accept(matchId, request == null ? null : request.getUserId());
    }

    @PostMapping("/matches/{matchId}/done")
    public SwapMatchDto done(@PathVariable Long matchId, @RequestBody SwapDoneRequest request) {
        return swapMatchService.markDone(matchId, request == null ? null : request.getUserId());
    }

    @PostMapping("/matches/{matchId}/review")
    public void review(@PathVariable Long matchId, @RequestBody SwapReviewRequest request) {
        swapMatchService.review(
                matchId,
                request == null ? null : request.getFromUserId(),
                request == null ? null : request.getRating(),
                request == null ? null : request.getComment()
        );
    }

    @GetMapping("/matches/{matchId}/reviews")
    public List<SwapReviewDto> reviewsForMatch(@PathVariable Long matchId) {
        return swapReviewService.listByMatch(matchId);
    }

    @GetMapping("/reviews/{userId}")
    public List<SwapReviewDto> reviewsForUser(@PathVariable Long userId) {
        return swapReviewService.listByUser(userId);
    }

    @DeleteMapping("/matches/{matchId}")
    public void deleteDoneMatch(
            @PathVariable Long matchId,
            @RequestParam Long userId
    ) {
        swapMatchService.deleteDoneMatch(matchId, userId);
    }

    @PostMapping("/rebuild")
    public SwapRebuildResponse rebuild() {
        swapMatchService.rebuildAll();
        SwapRebuildResponse response = new SwapRebuildResponse();
        response.setRequestCount(swapRequestRepository.count());
        response.setMatchCount(swapMatchService.matchCount());
        return response;
    }
}
