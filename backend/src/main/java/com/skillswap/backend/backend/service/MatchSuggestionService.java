package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.ExtractResponse;
import com.skillswap.backend.backend.dto.MatchSuggestionDto;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.model.UserSkillEntity;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import com.skillswap.backend.backend.repository.UserSkillRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class MatchSuggestionService {

    private final UserProfileRepository userProfileRepository;
    private final UserSkillRepository userSkillRepository;
    private final ExtractService extractService;
    private final MlModelService mlModelService;

    public MatchSuggestionService(
            UserProfileRepository userProfileRepository,
            UserSkillRepository userSkillRepository,
            ExtractService extractService,
            MlModelService mlModelService
    ) {
        this.userProfileRepository = userProfileRepository;
        this.userSkillRepository = userSkillRepository;
        this.extractService = extractService;
        this.mlModelService = mlModelService;
    }

    public List<MatchSuggestionDto> findMatches(Long requesterId, String text) {
        ExtractResponse extracted = extractService.extract(text);
        List<String> rawWants = safeList(extracted.getWants());
        List<String> rawOffers = safeList(extracted.getOffers());
        boolean hasInput = text != null && !text.trim().isBlank();
        if (rawWants.isEmpty() && rawOffers.isEmpty()) {
            if (hasInput) {
                rawWants = List.of(text.trim());
            } else {
                List<UserSkillEntity> requesterSkills = userSkillRepository.findByUserId(requesterId);
                rawWants = filterByTypeRaw(requesterSkills, "WANT");
                rawOffers = filterByTypeRaw(requesterSkills, "OFFER");
            }
        }
        List<String> wants = normalizeList(rawWants);
        List<String> offers = normalizeList(rawOffers);
        if (wants.isEmpty() && offers.isEmpty()) {
            return List.of();
        }
        String requesterLocation = userProfileRepository.findById(requesterId)
                .map(UserProfileEntity::getLocation)
                .orElse("");

        List<UserProfileEntity> users = userProfileRepository.findAll();
        List<MatchSuggestionDto> result = new ArrayList<>();

        for (UserProfileEntity candidate : users) {
            if (candidate.getId().equals(requesterId)) {
                continue;
            }

            List<UserSkillEntity> skills = userSkillRepository.findByUserId(candidate.getId());
            List<String> candidateOffers = filterByType(skills, "OFFER");
            List<String> candidateWants = filterByType(skills, "WANT");
            List<String> candidateOffersRaw = filterByTypeRaw(skills, "OFFER");
            List<String> candidateWantsRaw = filterByTypeRaw(skills, "WANT");

            int wantMatch = overlapScore(wants, candidateOffers);
            int offerMatch = overlapScore(offers, candidateWants);
            int semanticWantOverlap = semanticCategoryOverlap(rawWants, candidateOffersRaw);
            int semanticOfferOverlap = semanticCategoryOverlap(rawOffers, candidateWantsRaw);
            int semanticOverlap = semanticWantOverlap + semanticOfferOverlap;
            int semanticSignal = Math.max(wantMatch, semanticOverlap);
            boolean reciprocal = wantMatch > 0 && offerMatch > 0;

            if (!wants.isEmpty() && wantMatch == 0 && semanticWantOverlap == 0) {
                continue;
            }

            double mlScore = mlModelService.semanticScore(semanticSignal, offerMatch, candidate.getTrustScore(), reciprocal);
            boolean sameLocation = sameLocation(requesterLocation, candidate.getLocation());
            int locationBoost = sameLocation ? 6 : 0;
            int score = (int) Math.round(mlScore * 100) + locationBoost;
            MatchSuggestionDto dto = new MatchSuggestionDto();
            dto.setUserId(candidate.getId());
            dto.setName(candidate.getName());
            dto.setLocation(candidate.getLocation());
            dto.setTrustScore(candidate.getTrustScore());
            dto.setPhotoUrl(candidate.getPhotoUrl());
            dto.setMatchScore(Math.max(0, Math.min(100, score)));
            dto.setSemanticScore(Math.min(100, semanticSignal * 25));
            dto.setFairnessPercent(Math.max(45, Math.min(98, 55 + offerMatch * 20 + (reciprocal ? 15 : 0))));
            dto.setReason(reasonText(wantMatch, offerMatch, candidateOffers, candidateWants, reciprocal, sameLocation));
            dto.setBoost(Boolean.TRUE.equals(candidate.getBoost()));
            result.add(dto);
        }

        return result.stream()
                .sorted(
                        Comparator.comparing(MatchSuggestionDto::getBoost, Comparator.nullsLast(Comparator.reverseOrder()))
                                .thenComparing(Comparator.comparingInt(MatchSuggestionDto::getMatchScore).reversed())
                )
                .limit(5)
                .toList();
    }

    private List<String> safeList(List<String> list) {
        return list == null ? List.of() : list;
    }

    private List<String> normalizeList(List<String> list) {
        return list.stream()
                .map(SkillNormalizer::normalize)
                .filter(s -> !s.isBlank())
                .toList();
    }

    private String normalizedSkillOf(UserSkillEntity skill) {
        String normalized = skill.getNormalizedSkill();
        if (normalized != null && !normalized.isBlank()) {
            return normalized;
        }
        return SkillNormalizer.normalize(skill.getSkillName());
    }

    private List<String> filterByType(List<UserSkillEntity> skills, String type) {
        return skills.stream()
                .filter(s -> type.equals(s.getSkillType()))
                .map(this::normalizedSkillOf)
                .toList();
    }

    private List<String> filterByTypeRaw(List<UserSkillEntity> skills, String type) {
        return skills.stream()
                .filter(s -> type.equals(s.getSkillType()))
                .map(UserSkillEntity::getSkillName)
                .toList();
    }

    private int overlapScore(List<String> left, List<String> right) {
        int score = 0;
        for (String l : left) {
            if (l == null || l.isBlank()) {
                continue;
            }
            String normalizedLeft = SkillNormalizer.normalize(l);
            for (String r : right) {
                if (r == null || r.isBlank()) {
                    continue;
                }
                String normalizedRight = SkillNormalizer.normalize(r);
                if (normalizedRight.equals(normalizedLeft)) {
                    score++;
                    break;
                }
                if (normalizedRight.contains(normalizedLeft) || normalizedLeft.contains(normalizedRight)) {
                    score++;
                    break;
                }
                for (String token : normalizedLeft.split("[^\\p{L}0-9]+")) {
                    if (!token.isBlank() && normalizedRight.contains(token)) {
                        score++;
                        break;
                    }
                }
            }
        }
        return score;
    }

    private int semanticCategoryOverlap(List<String> left, List<String> right) {
        Map<String, List<String>> categories = mlModelService.semanticCategories();
        int score = 0;
        for (String leftItem : left) {
            String leftCategory = findCategory(leftItem, categories);
            if (leftCategory == null) {
                continue;
            }
            for (String rightItem : right) {
                String rightCategory = findCategory(rightItem, categories);
                if (leftCategory.equals(rightCategory)) {
                    score++;
                    break;
                }
            }
        }
        return score;
    }

    private String findCategory(String text, Map<String, List<String>> categories) {
        if (text == null || text.isBlank()) {
            return null;
        }
        String lower = text.toLowerCase(Locale.ROOT);
        for (Map.Entry<String, List<String>> entry : categories.entrySet()) {
            for (String keyword : entry.getValue()) {
                if (lower.contains(keyword.toLowerCase(Locale.ROOT))) {
                    return entry.getKey();
                }
            }
        }
        return null;
    }

    private String reasonText(
            int wantMatch,
            int offerMatch,
            List<String> candidateOffers,
            List<String> candidateWants,
            boolean reciprocal,
            boolean sameLocation
    ) {
        if (reciprocal) {
            return sameLocation
                    ? "Ayni konumda karsilikli ihtiyac ve yetenek uyumu bulundu."
                    : "Karşılıklı ihtiyaç ve yetenek uyumu bulundu.";
        }
        if (wantMatch > 0) {
            return "İhtiyacın için güçlü yetenek uyumu var: " + candidateOffers.stream().findFirst().orElse("Genel destek");
        }
        if (offerMatch > 0) {
            return "Senin sunabildiğin yetenek adayın ihtiyaçlarıyla uyumlu: " + candidateWants.stream().findFirst().orElse("Genel destek");
        }
        return sameLocation
                ? "Ayni konumda guven puani yuksek aday."
                : "Kısmi eşleşme, güven puanı yüksek aday.";
    }

    private boolean sameLocation(String left, String right) {
        if (left == null || right == null) {
            return false;
        }
        String l = left.trim().toLowerCase(Locale.ROOT);
        String r = right.trim().toLowerCase(Locale.ROOT);
        if (l.isEmpty() || r.isEmpty()) {
            return false;
        }
        return l.equals(r) || l.contains(r) || r.contains(l);
    }
}
