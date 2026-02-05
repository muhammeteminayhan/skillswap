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

@Service
public class MatchSuggestionService {

    private final UserProfileRepository userProfileRepository;
    private final UserSkillRepository userSkillRepository;
    private final ExtractService extractService;

    public MatchSuggestionService(
            UserProfileRepository userProfileRepository,
            UserSkillRepository userSkillRepository,
            ExtractService extractService
    ) {
        this.userProfileRepository = userProfileRepository;
        this.userSkillRepository = userSkillRepository;
        this.extractService = extractService;
    }

    public List<MatchSuggestionDto> findMatches(Long requesterId, String text) {
        ExtractResponse extracted = extractService.extract(text);
        List<String> wants = safeList(extracted.getWants());
        List<String> offers = safeList(extracted.getOffers());

        List<UserProfileEntity> users = userProfileRepository.findAll();
        List<MatchSuggestionDto> result = new ArrayList<>();

        for (UserProfileEntity candidate : users) {
            if (candidate.getId().equals(requesterId)) {
                continue;
            }

            List<UserSkillEntity> skills = userSkillRepository.findByUserId(candidate.getId());
            List<String> candidateOffers = filterByType(skills, "OFFER");
            List<String> candidateWants = filterByType(skills, "WANT");

            int wantMatch = overlapScore(wants, candidateOffers);
            int offerMatch = overlapScore(offers, candidateWants);
            int score = Math.min(100, 30 + wantMatch * 25 + offerMatch * 20 + candidate.getTrustScore() / 5);

            MatchSuggestionDto dto = new MatchSuggestionDto();
            dto.setUserId(candidate.getId());
            dto.setName(candidate.getName());
            dto.setLocation(candidate.getLocation());
            dto.setTrustScore(candidate.getTrustScore());
            dto.setMatchScore(score);
            dto.setReason(reasonText(wantMatch, offerMatch, candidateOffers, candidateWants));
            result.add(dto);
        }

        return result.stream()
                .sorted(Comparator.comparingInt(MatchSuggestionDto::getMatchScore).reversed())
                .limit(5)
                .toList();
    }

    private List<String> safeList(List<String> list) {
        return list == null ? List.of() : list;
    }

    private List<String> filterByType(List<UserSkillEntity> skills, String type) {
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
            String normalizedLeft = l.toLowerCase(Locale.ROOT);
            for (String r : right) {
                if (r == null || r.isBlank()) {
                    continue;
                }
                String normalizedRight = r.toLowerCase(Locale.ROOT);
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

    private String reasonText(int wantMatch, int offerMatch, List<String> candidateOffers, List<String> candidateWants) {
        if (wantMatch > 0 && offerMatch > 0) {
            return "Karşılıklı ihtiyaç ve yetenek uyumu bulundu.";
        }
        if (wantMatch > 0) {
            return "İhtiyacın için güçlü yetenek uyumu var: " + candidateOffers.stream().findFirst().orElse("Genel destek");
        }
        if (offerMatch > 0) {
            return "Senin sunabildiğin yetenek adayın ihtiyaçlarıyla uyumlu: " + candidateWants.stream().findFirst().orElse("Genel destek");
        }
        return "Kısmi eşleşme, güven puanı yüksek aday.";
    }
}
