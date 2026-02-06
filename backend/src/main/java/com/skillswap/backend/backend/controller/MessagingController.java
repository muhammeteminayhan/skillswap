package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.ChatMessageDto;
import com.skillswap.backend.backend.dto.ConversationSummaryDto;
import com.skillswap.backend.backend.dto.SendMessageRequest;
import com.skillswap.backend.backend.service.MessagingService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
public class MessagingController {

    private final MessagingService messagingService;

    public MessagingController(MessagingService messagingService) {
        this.messagingService = messagingService;
    }

    @GetMapping("/conversations/{userId}")
    public List<ConversationSummaryDto> conversations(@PathVariable Long userId) {
        return messagingService.conversations(userId);
    }

    @GetMapping("/thread")
    public List<ChatMessageDto> thread(
            @RequestParam Long userId,
            @RequestParam Long otherUserId
    ) {
        return messagingService.thread(userId, otherUserId);
    }

    @PostMapping("/send")
    public ChatMessageDto send(@Valid @RequestBody SendMessageRequest request) {
        return messagingService.send(request);
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgument(IllegalArgumentException exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("message", exception.getMessage()));
    }
}
