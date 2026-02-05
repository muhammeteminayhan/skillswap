package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.ChatRequest;
import com.skillswap.backend.backend.dto.ChatResponse;
import com.skillswap.backend.backend.service.ChatService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final ChatService chatService;

    public ChatController(ChatService chatService) {
        this.chatService = chatService;
    }

    @PostMapping
    public ChatResponse chat(@RequestBody ChatRequest request) {
        Long userId = request == null ? 1L : request.getUserId();
        String message = request == null ? "" : request.getMessage();
        return chatService.processMessage(userId, message);
    }
}
