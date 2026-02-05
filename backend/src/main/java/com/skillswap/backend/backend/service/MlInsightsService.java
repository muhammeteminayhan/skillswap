package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.MlInsightsResponse;
import com.skillswap.backend.backend.model.MessageEntity;
import com.skillswap.backend.backend.model.SwapRequestEntity;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.MessageRepository;
import com.skillswap.backend.backend.repository.SwapRequestRepository;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class MlInsightsService {

    private final MlModelService mlModelService;
    private final SwapRequestRepository swapRequestRepository;
    private final MessageRepository messageRepository;
    private final UserProfileRepository userProfileRepository;

    public MlInsightsService(
            MlModelService mlModelService,
            SwapRequestRepository swapRequestRepository,
            MessageRepository messageRepository,
            UserProfileRepository userProfileRepository
    ) {
        this.mlModelService = mlModelService;
        this.swapRequestRepository = swapRequestRepository;
        this.messageRepository = messageRepository;
        this.userProfileRepository = userProfileRepository;
    }

    public MlInsightsResponse buildInsights(Long userId) {
        Long resolvedUserId = userId == null ? 1L : userId;
        int openRequests = (int) swapRequestRepository.countByUserIdAndStatus(resolvedUserId, "OPEN");
        int unreadMessages = (int) messageRepository.countByUserIdAndUnreadTrue(resolvedUserId);
        int daysInactive = calculateDaysInactive(resolvedUserId);
        int trustScore = userProfileRepository.findById(resolvedUserId)
                .map(UserProfileEntity::getTrustScore)
                .orElse(70);

        int churnRisk = (int) Math.round(
                mlModelService.predictChurnProbability(daysInactive, openRequests, unreadMessages, trustScore) * 100
        );

        MlInsightsResponse response = new MlInsightsResponse();
        response.setUserId(resolvedUserId);
        response.setOpenRequests(openRequests);
        response.setUnreadMessages(unreadMessages);
        response.setDaysInactive(daysInactive);
        response.setChurnRiskPercent(Math.max(0, Math.min(100, churnRisk)));
        response.setModelVersion(mlModelService.getVersion());
        response.setActions(suggestActions(response.getChurnRiskPercent(), openRequests, unreadMessages));
        return response;
    }

    private int calculateDaysInactive(Long userId) {
        SwapRequestEntity latestRequest = swapRequestRepository.findTopByUserIdOrderByCreatedAtDesc(userId);
        MessageEntity latestMessage = messageRepository.findTopByUserIdOrderByCreatedAtDesc(userId);

        LocalDateTime now = LocalDateTime.now();
        LocalDateTime latest = null;

        if (latestRequest != null) {
            latest = latestRequest.getCreatedAt();
        }
        if (latestMessage != null && (latest == null || latestMessage.getCreatedAt().isAfter(latest))) {
            latest = latestMessage.getCreatedAt();
        }

        if (latest == null) {
            return 14;
        }
        return (int) Math.max(0, Duration.between(latest, now).toDays());
    }

    private List<String> suggestActions(int churnRisk, int openRequests, int unreadMessages) {
        List<String> tips = new ArrayList<>();
        if (churnRisk >= 70) {
            tips.add("Bugün en az bir yeni takas isteği aç ve hızlı eşleşme dene.");
            tips.add("AI sohbetinde ihtiyacını daha detaylı yaz, daha iyi adaylar gelir.");
        }
        if (openRequests > 2) {
            tips.add("Açık isteklerin fazla; en güçlü 1-2 isteğe odaklanıp güncelle.");
        }
        if (unreadMessages > 0) {
            tips.add("Okunmamış mesajlara hızlı dönmek eşleşme başarı oranını artırır.");
        }
        if (tips.isEmpty()) {
            tips.add("Aktiviten iyi görünüyor, aynı tempoda devam.");
        }
        return tips;
    }
}
