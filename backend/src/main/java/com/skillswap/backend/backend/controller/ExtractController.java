package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.ExtractRequest;
import com.skillswap.backend.backend.dto.ExtractResponse;
import com.skillswap.backend.backend.service.ExtractService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ExtractController {

    private final ExtractService extractService;

    public ExtractController(ExtractService extractService) {
        this.extractService = extractService;
    }

    @PostMapping("/extract")
    public ExtractResponse extract(@RequestBody ExtractRequest request) {
        return extractService.extract(request != null ? request.getText() : "");
    }
}
