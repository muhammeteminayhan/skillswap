package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.SwapReviewDto;
import com.skillswap.backend.backend.model.SwapReviewEntity;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.SwapReviewRepository;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class SwapReviewService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm");

    private final SwapReviewRepository swapReviewRepository;
    private final UserProfileRepository userProfileRepository;

    public SwapReviewService(
            SwapReviewRepository swapReviewRepository,
            UserProfileRepository userProfileRepository
    ) {
        this.swapReviewRepository = swapReviewRepository;
        this.userProfileRepository = userProfileRepository;
    }

    public List<SwapReviewDto> listByMatch(Long matchId) {
        return swapReviewRepository.findByMatchIdOrderByCreatedAtDesc(matchId)
                .stream()
                .map(this::toDto)
                .toList();
    }

    public List<SwapReviewDto> listByUser(Long userId) {
        return swapReviewRepository.findByToUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toDto)
                .toList();
    }

    private SwapReviewDto toDto(SwapReviewEntity entity) {
        SwapReviewDto dto = new SwapReviewDto();
        dto.setId(entity.getId());
        dto.setMatchId(entity.getMatchId());
        dto.setFromUserId(entity.getFromUserId());
        dto.setToUserId(entity.getToUserId());
        dto.setRating(entity.getRating());
        dto.setComment(entity.getComment());
        UserProfileEntity from = userProfileRepository.findById(entity.getFromUserId()).orElse(null);
        dto.setFromName(from == null ? "Kullanici" : from.getName());
        dto.setCreatedAt(entity.getCreatedAt() == null ? "" : entity.getCreatedAt().format(DATE_FORMATTER));
        return dto;
    }
}
