package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.CreateSwapRequest;
import com.skillswap.backend.backend.dto.ExtractResponse;
import com.skillswap.backend.backend.dto.SwapRequestDto;
import com.skillswap.backend.backend.model.SwapRequestEntity;
import com.skillswap.backend.backend.repository.SwapRequestRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class SwapRequestService {

    private final SwapRequestRepository swapRequestRepository;
    private final ExtractService extractService;

    public SwapRequestService(SwapRequestRepository swapRequestRepository, ExtractService extractService) {
        this.swapRequestRepository = swapRequestRepository;
        this.extractService = extractService;
    }

    public List<SwapRequestDto> list(Long userId) {
        return swapRequestRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toDto)
                .toList();
    }

    public SwapRequestDto create(CreateSwapRequest request) {
        Long userId = request.getUserId() == null ? 1L : request.getUserId();
        String text = request.getText() == null ? "" : request.getText().trim();

        ExtractResponse extracted = extractService.extract(text);

        SwapRequestEntity entity = new SwapRequestEntity();
        entity.setUserId(userId);
        entity.setText(text);
        entity.setWantedSkill(firstOrDefault(extracted.getWants(), "Genel - destek"));
        entity.setOfferedSkill(firstOrDefault(extracted.getOffers(), "Genel - destek"));
        entity.setStatus("OPEN");
        entity.setCreatedAt(LocalDateTime.now());

        return toDto(swapRequestRepository.save(entity));
    }

    private String firstOrDefault(List<String> items, String fallback) {
        if (items == null || items.isEmpty() || items.getFirst() == null || items.getFirst().isBlank()) {
            return fallback;
        }
        return items.getFirst();
    }

    private SwapRequestDto toDto(SwapRequestEntity entity) {
        SwapRequestDto dto = new SwapRequestDto();
        dto.setId(entity.getId());
        dto.setUserId(entity.getUserId());
        dto.setText(entity.getText());
        dto.setWantedSkill(entity.getWantedSkill());
        dto.setOfferedSkill(entity.getOfferedSkill());
        dto.setStatus(entity.getStatus());
        dto.setCreatedAt(entity.getCreatedAt().toString());
        return dto;
    }
}
