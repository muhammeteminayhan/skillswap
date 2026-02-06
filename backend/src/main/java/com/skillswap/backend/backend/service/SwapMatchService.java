package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.SwapMatchDto;
import com.skillswap.backend.backend.model.SwapMatchEntity;
import com.skillswap.backend.backend.model.SwapRequestEntity;
import com.skillswap.backend.backend.model.SwapReviewEntity;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.SwapMatchRepository;
import com.skillswap.backend.backend.repository.SwapRequestRepository;
import com.skillswap.backend.backend.repository.SwapReviewRepository;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class SwapMatchService {

    private final SwapMatchRepository swapMatchRepository;
    private final SwapRequestRepository swapRequestRepository;
    private final UserProfileRepository userProfileRepository;
    private final SwapReviewRepository swapReviewRepository;
    private final CreditValuationService creditValuationService;
    private final CreditService creditService;
    private final CreditConfig creditConfig;
    private final TrustScoreService trustScoreService;

    public SwapMatchService(
            SwapMatchRepository swapMatchRepository,
            SwapRequestRepository swapRequestRepository,
            UserProfileRepository userProfileRepository,
            SwapReviewRepository swapReviewRepository,
            CreditValuationService creditValuationService,
            CreditService creditService,
            CreditConfig creditConfig,
            TrustScoreService trustScoreService
    ) {
        this.swapMatchRepository = swapMatchRepository;
        this.swapRequestRepository = swapRequestRepository;
        this.userProfileRepository = userProfileRepository;
        this.swapReviewRepository = swapReviewRepository;
        this.creditValuationService = creditValuationService;
        this.creditService = creditService;
        this.creditConfig = creditConfig;
        this.trustScoreService = trustScoreService;
    }

    @Transactional
    public void rebuildAll() {
        swapMatchRepository.deleteAll();
        List<SwapRequestEntity> requests = swapRequestRepository.findAllByOrderByCreatedAtDesc();
        Set<String> created = new HashSet<>();
        for (int i = 0; i < requests.size(); i++) {
            for (int j = i + 1; j < requests.size(); j++) {
                SwapRequestEntity a = requests.get(i);
                SwapRequestEntity b = requests.get(j);
                if (a.getUserId().equals(b.getUserId())) {
                    continue;
                }
                if (!"OPEN".equals(a.getStatus()) || !"OPEN".equals(b.getStatus())) {
                    continue;
                }
                if (!isReciprocal(a, b)) {
                    continue;
                }
                long left = Math.min(a.getId(), b.getId());
                long right = Math.max(a.getId(), b.getId());
                String key = left + "-" + right;
                if (created.contains(key)) {
                    continue;
                }
                created.add(key);
                createMatch(a, b);
            }
        }
    }

    public List<SwapMatchDto> listForUser(Long userId) {
        List<SwapMatchDto> matches = swapMatchRepository.findByUserAIdOrUserBIdOrderByUpdatedAtDesc(userId, userId)
                .stream()
                .map(match -> toDto(match, userId))
                .toList();
        if (matches.isEmpty()) {
            rebuildAll();
            return swapMatchRepository.findByUserAIdOrUserBIdOrderByUpdatedAtDesc(userId, userId)
                    .stream()
                    .map(match -> toDto(match, userId))
                    .toList();
        }
        return matches;
    }

    public long matchCount() {
        return swapMatchRepository.count();
    }

    @Transactional
    public SwapMatchDto accept(Long matchId, Long userId) {
        SwapMatchEntity match = swapMatchRepository.findById(matchId)
                .orElseThrow(() -> new IllegalArgumentException("Eslesme bulunamadi."));
        if (userId == null) {
            throw new IllegalArgumentException("Kullanici gerekli.");
        }
        CreditSettlement settlement = buildSettlement(match);
        if (settlement.requiredCredits > 0
                && settlement.payerUserId != null
                && userId.equals(settlement.payerUserId)
                && !creditService.hasEnoughCredits(userId, settlement.requiredCredits)) {
            throw new IllegalArgumentException("Kredi yetersiz. Onaydan once kredi tamamlaman gerekiyor.");
        }
        if (userId.equals(match.getUserAId())) {
            match.setAcceptedByA(true);
        } else if (userId.equals(match.getUserBId())) {
            match.setAcceptedByB(true);
        } else {
            throw new IllegalArgumentException("Bu eslesmeye erisemezsiniz.");
        }
        if (Boolean.TRUE.equals(match.getAcceptedByA()) && Boolean.TRUE.equals(match.getAcceptedByB())) {
            if (settlement.requiredCredits > 0) {
                creditService.settleMatch(
                        match.getId(),
                        settlement.payerUserId,
                        settlement.receiverUserId,
                        settlement.requiredCredits,
                        settlement.description
                );
            }
            match.setStatus("ACCEPTED");
            // Remove requests from pool once matched to prevent re-matching
            swapRequestRepository.deleteById(match.getRequestAId());
            swapRequestRepository.deleteById(match.getRequestBId());
        }
        match.setUpdatedAt(LocalDateTime.now());
        return toDto(swapMatchRepository.save(match), userId);
    }

    @Transactional
    public SwapMatchDto markDone(Long matchId, Long userId) {
        SwapMatchEntity match = swapMatchRepository.findById(matchId)
                .orElseThrow(() -> new IllegalArgumentException("Eslesme bulunamadi."));
        if (userId == null) {
            throw new IllegalArgumentException("Kullanici gerekli.");
        }
        if (!"ACCEPTED".equals(match.getStatus())) {
            throw new IllegalArgumentException("Takas kabul edilmeden tamamlanamaz.");
        }
        if (userId.equals(match.getUserAId())) {
            match.setDoneByA(true);
        } else if (userId.equals(match.getUserBId())) {
            match.setDoneByB(true);
        } else {
            throw new IllegalArgumentException("Bu eslesmeye erisemezsiniz.");
        }
        if (Boolean.TRUE.equals(match.getDoneByA()) && Boolean.TRUE.equals(match.getDoneByB())) {
            match.setStatus("DONE");
        }
        match.setUpdatedAt(LocalDateTime.now());
        return toDto(swapMatchRepository.save(match), userId);
    }

    @Transactional
    public void review(Long matchId, Long fromUserId, Integer rating, String comment) {
        SwapMatchEntity match = swapMatchRepository.findById(matchId)
                .orElseThrow(() -> new IllegalArgumentException("Eslesme bulunamadi."));
        if (!"DONE".equals(match.getStatus())) {
            throw new IllegalArgumentException("Takas tamamlanmadan yorum yapilamaz.");
        }
        if (fromUserId == null) {
            throw new IllegalArgumentException("Kullanici gerekli.");
        }
        if (rating == null || rating < 1 || rating > 5) {
            throw new IllegalArgumentException("Puan 1-5 arasi olmali.");
        }
        if (swapReviewRepository.existsByMatchIdAndFromUserId(matchId, fromUserId)) {
            throw new IllegalArgumentException("Bu takas icin daha once yorum yaptiniz.");
        }
        Long toUserId = fromUserId.equals(match.getUserAId()) ? match.getUserBId() : match.getUserAId();
        SwapReviewEntity review = new SwapReviewEntity();
        review.setMatchId(matchId);
        review.setFromUserId(fromUserId);
        review.setToUserId(toUserId);
        review.setRating(rating);
        review.setComment(comment == null ? "" : comment.trim());
        review.setCreatedAt(LocalDateTime.now());
        swapReviewRepository.save(review);
        trustScoreService.applyReview(toUserId, rating);
    }

    private boolean isReciprocal(SwapRequestEntity a, SwapRequestEntity b) {
        String aWant = SkillNormalizer.normalize(a.getWantedSkill());
        String aOffer = SkillNormalizer.normalize(a.getOfferedSkill());
        String bWant = SkillNormalizer.normalize(b.getWantedSkill());
        String bOffer = SkillNormalizer.normalize(b.getOfferedSkill());
        return aWant.equals(bOffer) && aOffer.equals(bWant);
    }

    private void createMatch(SwapRequestEntity a, SwapRequestEntity b) {
        SwapMatchEntity match = new SwapMatchEntity();
        match.setUserAId(a.getUserId());
        match.setUserBId(b.getUserId());
        match.setRequestAId(a.getId());
        match.setRequestBId(b.getId());
        match.setRequestAWanted(a.getWantedSkill());
        match.setRequestAOffered(a.getOfferedSkill());
        match.setRequestBWanted(b.getWantedSkill());
        match.setRequestBOffered(b.getOfferedSkill());
        match.setAcceptedByA(false);
        match.setAcceptedByB(false);
        match.setDoneByA(false);
        match.setDoneByB(false);
        match.setStatus("PENDING");
        match.setCreatedAt(LocalDateTime.now());
        match.setUpdatedAt(LocalDateTime.now());
        swapMatchRepository.save(match);
    }

    private SwapMatchDto toDto(SwapMatchEntity match, Long viewerId) {
        SwapRequestEntity reqA = swapRequestRepository.findById(match.getRequestAId()).orElse(null);
        SwapRequestEntity reqB = swapRequestRepository.findById(match.getRequestBId()).orElse(null);
        Long otherId = viewerId.equals(match.getUserAId()) ? match.getUserBId() : match.getUserAId();
        UserProfileEntity other = userProfileRepository.findById(otherId).orElse(null);

        SwapMatchDto dto = new SwapMatchDto();
        dto.setMatchId(match.getId());
        dto.setStatus(match.getStatus());
        dto.setOtherUserId(otherId);
        dto.setOtherName(other == null ? "Kullanici" : other.getName());
        if (viewerId.equals(match.getUserAId())) {
            dto.setMyWanted(reqA == null ? match.getRequestAWanted() : reqA.getWantedSkill());
            dto.setMyOffered(reqA == null ? match.getRequestAOffered() : reqA.getOfferedSkill());
            dto.setOtherWanted(reqB == null ? match.getRequestBWanted() : reqB.getWantedSkill());
            dto.setOtherOffered(reqB == null ? match.getRequestBOffered() : reqB.getOfferedSkill());
            dto.setAcceptedByMe(match.getAcceptedByA());
            dto.setAcceptedByOther(match.getAcceptedByB());
            dto.setDoneByMe(match.getDoneByA());
            dto.setDoneByOther(match.getDoneByB());
        } else {
            dto.setMyWanted(reqB == null ? match.getRequestBWanted() : reqB.getWantedSkill());
            dto.setMyOffered(reqB == null ? match.getRequestBOffered() : reqB.getOfferedSkill());
            dto.setOtherWanted(reqA == null ? match.getRequestAWanted() : reqA.getWantedSkill());
            dto.setOtherOffered(reqA == null ? match.getRequestAOffered() : reqA.getOfferedSkill());
            dto.setAcceptedByMe(match.getAcceptedByB());
            dto.setAcceptedByOther(match.getAcceptedByA());
            dto.setDoneByMe(match.getDoneByB());
            dto.setDoneByOther(match.getDoneByA());
        }
        boolean canReview = "DONE".equals(match.getStatus())
                && !swapReviewRepository.existsByMatchIdAndFromUserId(match.getId(), viewerId);
        dto.setCanReview(canReview);
        applyCreditInfo(dto, match, viewerId, otherId);
        return dto;
    }

    private void applyCreditInfo(SwapMatchDto dto, SwapMatchEntity match, Long viewerId, Long otherId) {
        int myCredit = creditValuationService.evaluate(viewerId, dto.getMyOffered());
        int otherCredit = creditValuationService.evaluate(otherId, dto.getOtherOffered());
        int diff = Math.abs(myCredit - otherCredit);
        int max = Math.max(myCredit, otherCredit);
        int fairness = max == 0 ? 100 : Math.max(0, 100 - (int) Math.round((diff * 100.0) / max));
        boolean creditRequiredByMe = diff > 0 && myCredit < otherCredit;
        int requiredAmount = diff * creditConfig.getPricePerCredit();
        int platformFee = (int) Math.round(requiredAmount * creditConfig.getPlatformFeeRate());
        int payout = requiredAmount - platformFee;

        dto.setMyCredit(myCredit);
        dto.setOtherCredit(otherCredit);
        dto.setCreditDiff(diff);
        dto.setFairnessPercent(fairness);
        dto.setCreditRequiredByMe(creditRequiredByMe);
        dto.setRequiredCredits(diff);
        dto.setPricePerCredit(creditConfig.getPricePerCredit());
        dto.setPlatformFeeRate(creditConfig.getPlatformFeeRate());
        dto.setRequiredAmountTl(requiredAmount);
        dto.setPlatformFeeAmountTl(platformFee);
        dto.setPayoutAmountTl(payout);
    }

    private CreditSettlement buildSettlement(SwapMatchEntity match) {
        SwapRequestEntity reqA = swapRequestRepository.findById(match.getRequestAId()).orElse(null);
        SwapRequestEntity reqB = swapRequestRepository.findById(match.getRequestBId()).orElse(null);
        String offeredA = reqA == null ? match.getRequestAOffered() : reqA.getOfferedSkill();
        String offeredB = reqB == null ? match.getRequestBOffered() : reqB.getOfferedSkill();
        int creditA = creditValuationService.evaluate(match.getUserAId(), offeredA);
        int creditB = creditValuationService.evaluate(match.getUserBId(), offeredB);
        CreditSettlement settlement = new CreditSettlement();
        if (creditA == creditB) {
            settlement.requiredCredits = 0;
            settlement.payerUserId = null;
            settlement.receiverUserId = null;
            settlement.description = "Takas kredileri esitlendi.";
            return settlement;
        }
        if (creditA < creditB) {
            settlement.payerUserId = match.getUserAId();
            settlement.receiverUserId = match.getUserBId();
            settlement.requiredCredits = creditB - creditA;
        } else {
            settlement.payerUserId = match.getUserBId();
            settlement.receiverUserId = match.getUserAId();
            settlement.requiredCredits = creditA - creditB;
        }
        settlement.description = "Takas kredi dengelemesi";
        return settlement;
    }

    private static class CreditSettlement {
        private Long payerUserId;
        private Long receiverUserId;
        private int requiredCredits;
        private String description;
    }
}
