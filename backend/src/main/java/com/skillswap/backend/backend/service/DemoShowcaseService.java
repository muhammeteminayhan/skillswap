package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.BoostPlanDto;
import com.skillswap.backend.backend.dto.BoostActivationResponse;
import com.skillswap.backend.backend.dto.BoostResponse;
import com.skillswap.backend.backend.dto.ChainsResponse;
import com.skillswap.backend.backend.dto.DashboardResponse;
import com.skillswap.backend.backend.dto.HighlightCardDto;
import com.skillswap.backend.backend.dto.MatchSuggestionDto;
import com.skillswap.backend.backend.dto.QuantumMatchDto;
import com.skillswap.backend.backend.dto.QuantumResponse;
import com.skillswap.backend.backend.dto.SearchResponse;
import com.skillswap.backend.backend.dto.StatCardDto;
import com.skillswap.backend.backend.dto.TalentResponse;
import com.skillswap.backend.backend.dto.TalentSuggestionDto;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.SwapRequestRepository;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class DemoShowcaseService {

    private final UserProfileRepository userProfileRepository;
    private final SwapRequestRepository swapRequestRepository;
    private final MatchSuggestionService matchSuggestionService;
    private final MlModelService mlModelService;
    private final HiddenTalentService hiddenTalentService;

    public DemoShowcaseService(
            UserProfileRepository userProfileRepository,
            SwapRequestRepository swapRequestRepository,
            MatchSuggestionService matchSuggestionService,
            MlModelService mlModelService,
            HiddenTalentService hiddenTalentService
    ) {
        this.userProfileRepository = userProfileRepository;
        this.swapRequestRepository = swapRequestRepository;
        this.matchSuggestionService = matchSuggestionService;
        this.mlModelService = mlModelService;
        this.hiddenTalentService = hiddenTalentService;
    }

    public DashboardResponse dashboard(Long userId) {
        Long id = userId == null ? 1L : userId;
        UserProfileEntity user = userProfileRepository.findById(id).orElse(null);
        String name = user == null ? "Demo Kullanıcı" : user.getName();
        int reputation = user == null ? 80 : user.getTrustScore();
        int swapCount = (int) swapRequestRepository.countByUserId(id);

        DashboardResponse response = new DashboardResponse();
        response.setWelcomeText("Tekrar Hoş Geldin");
        response.setUserName(name);
        response.setReputation(reputation);
        response.setSwapCount(swapCount);
        response.setQuickStats(List.of(
                stat("İtibar", String.valueOf(reputation), "+5 bu ay"),
                stat("Açık Takas", String.valueOf(swapCount), "AI destekli eşleştirme aktif"),
                stat("Aktif İlan", String.valueOf(Math.max(1, swapCount)), "Yeni ilanlar yayınlandı")
        ));
        response.setHighlights(List.of(
                highlight("Quantum", "Superposition", "#6E55FF", "#4AB0FF"),
                highlight("Chains", "Döngüsel Takas", "#1DCC9C", "#2B8A79"),
                highlight("AI Chat", "Anlık Koç", "#42A5F5", "#1E88E5")
        ));
        return response;
    }

    public ChainsResponse chains(Long userId) {
        Long id = userId == null ? 1L : userId;
        int available = (int) Math.max(0, swapRequestRepository.countByUserId(id) - 1);
        ChainsResponse response = new ChainsResponse();
        response.setAvailableChains(available);
        response.setActiveChains(Math.min(2, available));
        response.setChainTips(List.of(
                "Yeni yetenek ekleyerek zincir sayısını artır.",
                "AI sohbetinde ihtiyacını net yazarsan zincir eşleşmesi yükselir.",
                "Konum bilgisi içeren istekler daha hızlı bağlanır."
        ));
        return response;
    }

    public QuantumResponse quantum(Long userId, boolean realMatching) {
        Long id = userId == null ? 1L : userId;
        List<MatchSuggestionDto> base = matchSuggestionService.findMatches(id, "Elektrik ve tesisat takası");

        List<QuantumMatchDto> matches = new ArrayList<>();
        for (MatchSuggestionDto item : base) {
            QuantumMatchDto q = new QuantumMatchDto();
            q.setUserId(item.getUserId());
            q.setName(item.getName());
            q.setTitle(item.getReason());
            q.setProbability(Math.max(45, item.getMatchScore()));
            q.setTags(List.of("AI", "Eşleşme", "Semantik"));
            q.setReason(item.getReason());
            matches.add(q);
        }

        QuantumResponse response = new QuantumResponse();
        response.setRealMatching(realMatching);
        response.setQuantumState(realMatching ? "Süperpozisyon Aktif" : "Demo Modu" );
        response.setEntanglements(realMatching ? Math.min(5, matches.size()) : 0);
        response.setMatches(matches);
        return response;
    }

    public TalentResponse talents(Long userId) {
        Long id = userId == null ? 1L : userId;
        TalentResponse response = new TalentResponse();
        response.setIntro("Topluluk verisinden ogrenilen beceri birliktelikleri ile senin icin ek yetenek onerileri.");
        response.setTalents(hiddenTalentService.findHiddenTalents(id));
        return response;
    }

    public SearchResponse search(Long userId, String query, Integer radiusKm) {
        Long id = userId == null ? 1L : userId;
        String q = query == null || query.isBlank() ? "genel destek" : query;
        int radius = radiusKm == null ? 5 : radiusKm;

        SearchResponse response = new SearchResponse();
        response.setQuery(q);
        response.setRadiusKm(radius);
        response.setResults(matchSuggestionService.findMatches(id, q));
        return response;
    }

    public BoostResponse boost() {
        BoostResponse response = new BoostResponse();
        response.setDescription("Boost ile profil görünürlüğünü artır, daha hızlı takas bul.");
        response.setPlans(List.of(
                plan("1 Hafta Boost", "₺69", List.of("7 gün görünürlük artışı", "Öncelikli listelenme", "AI hızlı eşleşme")),
                plan("1 Ay Boost", "₺199", List.of("Aylık üst sıralama", "10x profil görüntülenme", "Trend rozeti")),
                plan("1 Yıl Boost", "₺999", List.of("Yıllık maksimum görünürlük", "Öncelikli eşleşme", "Detaylı performans paneli"))
        ));
        return response;
    }

    public BoostActivationResponse activateBoost(Long userId) {
        Long id = userId == null ? 1L : userId;
        UserProfileEntity user = userProfileRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Kullanici bulunamadi."));
        user.setBoost(true);
        userProfileRepository.save(user);

        BoostActivationResponse response = new BoostActivationResponse();
        response.setBoost(user.getBoost());
        response.setMessage("Aktifleştirildi");
        return response;
    }

    public String modelVersion() {
        return mlModelService.getVersion();
    }

    private StatCardDto stat(String title, String value, String subtitle) {
        StatCardDto dto = new StatCardDto();
        dto.setTitle(title);
        dto.setValue(value);
        dto.setSubtitle(subtitle);
        return dto;
    }

    private HighlightCardDto highlight(String title, String subtitle, String from, String to) {
        HighlightCardDto dto = new HighlightCardDto();
        dto.setTitle(title);
        dto.setSubtitle(subtitle);
        dto.setGradientFrom(from);
        dto.setGradientTo(to);
        return dto;
    }

    private TalentSuggestionDto talent(String title, int matchPercent, String description) {
        TalentSuggestionDto dto = new TalentSuggestionDto();
        dto.setTitle(title);
        dto.setMatchPercent(matchPercent);
        dto.setDescription(description);
        return dto;
    }

    private BoostPlanDto plan(String title, String price, List<String> benefits) {
        BoostPlanDto dto = new BoostPlanDto();
        dto.setTitle(title);
        dto.setPrice(price);
        dto.setBenefits(benefits);
        return dto;
    }
}
