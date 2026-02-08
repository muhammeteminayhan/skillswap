package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.CreateSwapRequest;
import com.skillswap.backend.backend.dto.ExtractResponse;
import com.skillswap.backend.backend.dto.SwapRequestDto;
import com.skillswap.backend.backend.model.SwapRequestEntity;
import com.skillswap.backend.backend.model.UserSkillEntity;
import com.skillswap.backend.backend.repository.SwapRequestRepository;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import com.skillswap.backend.backend.repository.UserSkillRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class SwapRequestService {

    private final SwapRequestRepository swapRequestRepository;
    private final ExtractService extractService;
    private final UserSkillRepository userSkillRepository;
    private final UserProfileRepository userProfileRepository;
    private final SwapMatchService swapMatchService;

    public SwapRequestService(
            SwapRequestRepository swapRequestRepository,
            ExtractService extractService,
            UserSkillRepository userSkillRepository,
            UserProfileRepository userProfileRepository,
            SwapMatchService swapMatchService
    ) {
        this.swapRequestRepository = swapRequestRepository;
        this.extractService = extractService;
        this.userSkillRepository = userSkillRepository;
        this.userProfileRepository = userProfileRepository;
        this.swapMatchService = swapMatchService;
    }

    public List<SwapRequestDto> list(Long userId) {
        return swapRequestRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toDto)
                .toList();
    }

    public List<String> listWants(Long userId) {
        return swapRequestRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(SwapRequestEntity::getWantedSkill)
                .filter(s -> s != null && !s.isBlank())
                .distinct()
                .toList();
    }

    public List<SwapRequestDto> listAll() {
        return swapRequestRepository.findAllByOrderByCreatedAtDesc()
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
        String wanted = firstOrDefault(extracted.getWants(), "Genel - destek");
        String offered = firstOrDefault(extracted.getOffers(), "Genel - destek");
        entity.setText(buildTitle(wanted, offered));
        entity.setWantedSkill(wanted);
        entity.setOfferedSkill(offered);
        entity.setStatus("OPEN");
        entity.setCreatedAt(LocalDateTime.now());

        SwapRequestDto dto = toDto(swapRequestRepository.save(entity));
        swapMatchService.rebuildAll();
        return dto;
    }

    public void addWant(Long userId, String want) {
        if (userId == null) {
            throw new IllegalArgumentException("Kullanici gerekli.");
        }
        if (want == null || want.isBlank()) {
            throw new IllegalArgumentException("Ihtiyac bos olamaz.");
        }
        buildRequestsForUserWithWant(userId, want.trim());
        swapMatchService.rebuildAll();
    }

    public void deleteWant(Long userId, String want) {
        if (userId == null) {
            throw new IllegalArgumentException("Kullanici gerekli.");
        }
        if (want == null || want.isBlank()) {
            throw new IllegalArgumentException("Ihtiyac bos olamaz.");
        }
        swapRequestRepository.deleteByUserIdAndWantedSkillIgnoreCase(userId, want.trim());
        swapMatchService.rebuildAll();
    }

    public SwapRequestDto updateStatus(Long requestId, String status) {
        SwapRequestEntity entity = swapRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Takas istegi bulunamadi."));
        String normalized = status == null ? "" : status.trim().toUpperCase();
        if (!(normalized.equals("OPEN")
                || normalized.equals("DONE")
                || normalized.equals("CANCELLED")
                || normalized.equals("LOCKED"))) {
            throw new IllegalArgumentException("Gecersiz durum.");
        }
        entity.setStatus(normalized);
        return toDto(swapRequestRepository.save(entity));
    }

    public void rebuildForUser(Long userId) {
        if (userId == null) {
            return;
        }
        swapRequestRepository.deleteByUserId(userId);
        buildRequestsForUser(userId);
        swapMatchService.rebuildAll();
    }

    public void rebuildAll() {
        swapRequestRepository.deleteAll();
        userProfileRepository.findAll()
                .forEach(user -> buildRequestsForUser(user.getId()));
        swapMatchService.rebuildAll();
    }

    private void buildRequestsForUser(Long userId) {
        List<UserSkillEntity> skills = userSkillRepository.findByUserId(userId);
        List<String> offers = skills.stream()
                .filter(s -> "OFFER".equals(s.getSkillType()))
                .map(UserSkillEntity::getSkillName)
                .filter(s -> s != null && !s.isBlank())
                .toList();
        List<String> wants = skills.stream()
                .filter(s -> "WANT".equals(s.getSkillType()))
                .map(UserSkillEntity::getSkillName)
                .filter(s -> s != null && !s.isBlank())
                .toList();
        if (wants.isEmpty()) {
            return;
        }
        List<String> effectiveOffers = offers.isEmpty() ? List.of("Genel - destek") : offers;
        for (String want : wants) {
            buildRequestsForUserWithWant(userId, want);
        }
    }

    private void buildRequestsForUserWithWant(Long userId, String want) {
        List<UserSkillEntity> skills = userSkillRepository.findByUserId(userId);
        List<String> offers = skills.stream()
                .filter(s -> "OFFER".equals(s.getSkillType()))
                .map(UserSkillEntity::getSkillName)
                .filter(s -> s != null && !s.isBlank())
                .toList();
        List<String> effectiveOffers = offers.isEmpty() ? List.of("Genel - destek") : offers;
        for (String offer : effectiveOffers) {
            SwapRequestEntity entity = new SwapRequestEntity();
            entity.setUserId(userId);
            entity.setText(buildTitle(want, offer));
            entity.setWantedSkill(want);
            entity.setOfferedSkill(offer);
            entity.setStatus("OPEN");
            entity.setCreatedAt(LocalDateTime.now());
            swapRequestRepository.save(entity);
        }
    }

    private String firstOrDefault(List<String> items, String fallback) {
        if (items == null || items.isEmpty() || items.getFirst() == null || items.getFirst().isBlank()) {
            return fallback;
        }
        return items.getFirst();
    }

    private String buildTitle(String wanted, String offered) {
        return "Ihtiyacim: " + wanted + ". Karsiliginda " + offered + " sunuyorum.";
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
