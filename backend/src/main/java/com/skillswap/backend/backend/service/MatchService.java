package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.ExtractResponse;
import com.skillswap.backend.backend.dto.MatchCandidate;
import com.skillswap.backend.backend.dto.MatchResponse;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@Service
public class MatchService {

    private final ExtractService extractService;

    private final List<MockUser> mockUsers = List.of(
            new MockUser("Ahmet Usta", List.of("Elektrik - priz", "Elektrik - avize montajı"), 88),
            new MockUser("Merve Hanım", List.of("Doğalgaz - kombi bakımı", "Tesisat - petek temizliği"), 91),
            new MockUser("Selim", List.of("Tesisat - musluk tamiri", "Banyo - su kaçağı"), 79),
            new MockUser("Ece", List.of("Boya - iç cephe", "Alçı - duvar düzeltme"), 84),
            new MockUser("Kaan", List.of("PC tamir", "Laptop format", "Yazıcı kurulumu"), 87),
            new MockUser("Zehra", List.of("Elektrik - sigorta", "Aydınlatma sistemi"), 82),
            new MockUser("Burak", List.of("Mobilya montaj", "Kapı menteşe ayarı"), 76),
            new MockUser("Deniz", List.of("Doğalgaz - kombi bakımı", "Klima temizliği"), 90)
    );

    public MatchService(ExtractService extractService) {
        this.extractService = extractService;
    }

    public MatchResponse match(String text) {
        ExtractResponse extracted = extractService.extract(text);
        String firstWant = firstOrEmpty(extracted.getWants());
        String firstOffer = firstOrEmpty(extracted.getOffers());

        List<RankedCandidate> ranked = new ArrayList<>();
        for (MockUser user : mockUsers) {
            int matchScore = scoreWant(firstWant, user.skills());
            int fairnessPercent = scoreOffer(firstOffer, user.skills());

            MatchCandidate candidate = new MatchCandidate();
            candidate.setName(user.name());
            candidate.setSkills(user.skills());
            candidate.setTrustScore(user.trustScore());
            candidate.setMatchScore(matchScore);
            candidate.setFairnessPercent(fairnessPercent);

            int total = matchScore + fairnessPercent + user.trustScore();
            ranked.add(new RankedCandidate(candidate, total));
        }

        ranked.sort(Comparator.comparingInt(RankedCandidate::totalScore).reversed());

        MatchResponse response = new MatchResponse();
        response.setCandidates(ranked.stream().limit(5).map(RankedCandidate::candidate).toList());
        return response;
    }

    private String firstOrEmpty(List<String> items) {
        if (items == null || items.isEmpty() || items.get(0) == null) {
            return "";
        }
        return items.get(0);
    }

    private int scoreWant(String want, List<String> skills) {
        if (want.isBlank()) {
            return 40;
        }
        if (hasKeywordMatch(want, skills)) {
            return 90;
        }
        return 40;
    }

    private int scoreOffer(String offer, List<String> skills) {
        if (offer.isBlank()) {
            return 60;
        }
        return hasKeywordMatch(offer, skills) ? 80 : 60;
    }

    private boolean hasKeywordMatch(String input, List<String> skills) {
        String normalizedInput = input.toLowerCase(Locale.ROOT);
        for (String skill : skills) {
            String normalizedSkill = skill.toLowerCase(Locale.ROOT);
            if (normalizedSkill.contains(normalizedInput) || normalizedInput.contains(normalizedSkill)) {
                return true;
            }
            for (String token : normalizedInput.split("[^\\p{L}0-9]+")) {
                if (!token.isBlank() && normalizedSkill.contains(token)) {
                    return true;
                }
            }
        }
        return false;
    }

    private record MockUser(String name, List<String> skills, int trustScore) {
    }

    private record RankedCandidate(MatchCandidate candidate, int totalScore) {
    }
}
