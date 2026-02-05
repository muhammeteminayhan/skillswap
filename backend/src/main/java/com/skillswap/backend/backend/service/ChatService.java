package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.ai.GeminiClient;
import com.skillswap.backend.backend.dto.ChatResponse;
import com.skillswap.backend.backend.dto.MatchSuggestionDto;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ChatService {

    private final MatchSuggestionService matchSuggestionService;
    private final GeminiClient geminiClient;

    public ChatService(MatchSuggestionService matchSuggestionService, GeminiClient geminiClient) {
        this.matchSuggestionService = matchSuggestionService;
        this.geminiClient = geminiClient;
    }

    public ChatResponse processMessage(Long userId, String message) {
        Long resolvedUserId = userId == null ? 1L : userId;
        String safeMessage = message == null ? "" : message.trim();

        List<MatchSuggestionDto> suggestions = matchSuggestionService.findMatches(resolvedUserId, safeMessage);
        String fallbackAnswer = buildFallbackAnswer(suggestions);

        String aiAnswer = geminiClient.generateContent(buildAiPrompt(safeMessage, suggestions))
                .map(String::trim)
                .filter(s -> !s.isBlank())
                .orElse(fallbackAnswer);

        ChatResponse response = new ChatResponse();
        response.setAnswer(aiAnswer);
        response.setSuggestions(suggestions);
        return response;
    }

    private String buildFallbackAnswer(List<MatchSuggestionDto> suggestions) {
        if (suggestions.isEmpty()) {
            return "Şu an güçlü bir eşleşme bulamadım. İsteğini biraz daha detaylandırırsan daha iyi eşleştirebilirim.";
        }
        MatchSuggestionDto top = suggestions.getFirst();
        return "Sana " + suggestions.size() + " aday buldum. En güçlü eşleşme: " + top.getName() + " (" + top.getMatchScore() + "/100).";
    }

    private String buildAiPrompt(String userMessage, List<MatchSuggestionDto> suggestions) {
        StringBuilder sb = new StringBuilder();
        sb.append("Sen SkillSwap uygulamasında kullanıcıya yardımcı olan Türkçe bir asistanısın. ")
                .append("1-2 kısa cümleyle yanıt ver. Resmi değil, arkadaş canlısı ol.\n")
                .append("Kullanıcı mesajı: ").append(userMessage).append("\n")
                .append("Eşleşme adayları:\n");
        for (MatchSuggestionDto candidate : suggestions) {
            sb.append("- ")
                    .append(candidate.getName())
                    .append(" | skor=")
                    .append(candidate.getMatchScore())
                    .append(" | sebep=")
                    .append(candidate.getReason())
                    .append("\n");
        }
        sb.append("Eğer aday yoksa bunu nazikçe belirt.");
        return sb.toString();
    }
}
