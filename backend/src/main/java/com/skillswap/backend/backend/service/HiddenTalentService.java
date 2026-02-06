package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.TalentSuggestionDto;
import com.skillswap.backend.backend.model.UserSkillEntity;
import com.skillswap.backend.backend.repository.UserSkillRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Service
public class HiddenTalentService {

    private static final int MIN_COHORT_SIZE = 2;

    private final UserSkillRepository userSkillRepository;

    public HiddenTalentService(UserSkillRepository userSkillRepository) {
        this.userSkillRepository = userSkillRepository;
    }

    public List<TalentSuggestionDto> findHiddenTalents(Long userId) {
        List<UserSkillEntity> allOffers = userSkillRepository.findBySkillType("OFFER");
        Map<Long, Set<String>> userToSkills = buildSkillMap(allOffers);
        Set<String> userSkills = userToSkills.getOrDefault(userId, Set.of());

        if (userSkills.isEmpty()) {
            return fallbackTalents();
        }

        List<ScoredTalent> scored = new ArrayList<>();
        for (String currentSkill : userSkills) {
            Set<Long> cohort = usersWithSkill(userToSkills, currentSkill);
            if (cohort.size() < MIN_COHORT_SIZE) {
                continue;
            }

            Map<String, Integer> coCounts = new HashMap<>();
            for (Long candidateUserId : cohort) {
                for (String candidateSkill : userToSkills.getOrDefault(candidateUserId, Set.of())) {
                    if (!candidateSkill.equals(currentSkill) && !userSkills.contains(candidateSkill)) {
                        coCounts.merge(candidateSkill, 1, Integer::sum);
                    }
                }
            }

            for (Map.Entry<String, Integer> entry : coCounts.entrySet()) {
                int probability = (int) Math.round(entry.getValue() * 100.0 / cohort.size());
                if (probability >= 50) {
                    scored.add(new ScoredTalent(entry.getKey(), probability, currentSkill, cohort.size()));
                }
            }
        }

        if (scored.isEmpty()) {
            return fallbackTalents();
        }

        Map<String, ScoredTalent> bestPerSkill = new LinkedHashMap<>();
        for (ScoredTalent item : scored) {
            ScoredTalent existing = bestPerSkill.get(item.skill);
            if (existing == null || item.percent > existing.percent) {
                bestPerSkill.put(item.skill, item);
            }
        }

        return bestPerSkill.values().stream()
                .sorted(Comparator.comparingInt((ScoredTalent s) -> s.percent).reversed())
                .limit(3)
                .map(this::toDto)
                .toList();
    }

    private Map<Long, Set<String>> buildSkillMap(List<UserSkillEntity> allOffers) {
        Map<Long, Set<String>> map = new HashMap<>();
        for (UserSkillEntity skill : allOffers) {
            String normalized = normalize(skill.getSkillName());
            if (normalized.isEmpty()) {
                continue;
            }
            map.computeIfAbsent(skill.getUserId(), ignored -> new HashSet<>()).add(normalized);
        }
        return map;
    }

    private Set<Long> usersWithSkill(Map<Long, Set<String>> userToSkills, String skill) {
        Set<Long> result = new HashSet<>();
        for (Map.Entry<Long, Set<String>> entry : userToSkills.entrySet()) {
            if (entry.getValue().contains(skill)) {
                result.add(entry.getKey());
            }
        }
        return result;
    }

    private TalentSuggestionDto toDto(ScoredTalent item) {
        TalentSuggestionDto dto = new TalentSuggestionDto();
        dto.setTitle(display(item.skill));
        dto.setMatchPercent(item.percent);
        dto.setDescription(String.format(
                Locale.ROOT,
                "%d kisilik benzer grupta '%s' yetenegine sahip olanlarin %%%d'i ayni zamanda '%s' becerisini ekliyor.",
                item.sampleSize,
                display(item.basisSkill),
                item.percent,
                display(item.skill)
        ));
        return dto;
    }

    private List<TalentSuggestionDto> fallbackTalents() {
        return List.of(
                createFallback("Elektrik", 80, "Tesisat odakli profillerin buyuk bolumu elektrik becerisini de ekliyor."),
                createFallback("Boya", 72, "Ev ici teknik islerle ugrasanlar boya becerisiyle daha fazla takas buluyor."),
                createFallback("Kucuk Onarim", 68, "Coklu beceri sunan profiller eslesmelerde daha onde cikiyor.")
        );
    }

    private TalentSuggestionDto createFallback(String title, int percent, String description) {
        TalentSuggestionDto dto = new TalentSuggestionDto();
        dto.setTitle(title);
        dto.setMatchPercent(percent);
        dto.setDescription(description);
        return dto;
    }

    private String normalize(String raw) {
        if (raw == null) {
            return "";
        }
        String lower = raw.toLowerCase(Locale.forLanguageTag("tr"));
        String base = lower.split("-")[0].trim();
        return base
                .replace("ı", "i")
                .replace("ş", "s")
                .replace("ğ", "g")
                .replace("ç", "c")
                .replace("ö", "o")
                .replace("ü", "u");
    }

    private String display(String normalized) {
        if (normalized.isBlank()) {
            return normalized;
        }
        return normalized.substring(0, 1).toUpperCase(Locale.ROOT) + normalized.substring(1);
    }

    private record ScoredTalent(String skill, int percent, String basisSkill, int sampleSize) {
    }
}
