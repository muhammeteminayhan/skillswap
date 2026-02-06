package com.skillswap.backend.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.boot.context.event.ApplicationReadyEvent;

import com.skillswap.backend.backend.repository.SwapRequestRepository;

@Component
public class SwapAutoSyncService {

    private final SwapRequestService swapRequestService;
    private final SwapRequestRepository swapRequestRepository;
    private final SwapMatchService swapMatchService;
    private final boolean rebuildOnStartup;

    public SwapAutoSyncService(
            SwapRequestService swapRequestService,
            SwapRequestRepository swapRequestRepository,
            SwapMatchService swapMatchService,
            @Value("${app.swap.rebuildOnStartup:true}") boolean rebuildOnStartup
    ) {
        this.swapRequestService = swapRequestService;
        this.swapRequestRepository = swapRequestRepository;
        this.swapMatchService = swapMatchService;
        this.rebuildOnStartup = rebuildOnStartup;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void onReady() {
        if (rebuildOnStartup) {
            if (swapRequestRepository.count() == 0) {
                swapRequestService.rebuildAll();
            } else {
                swapMatchService.rebuildAll();
            }
        }
    }
}
