package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.CreditBalanceDto;
import com.skillswap.backend.backend.dto.CreditPurchaseRequest;
import com.skillswap.backend.backend.dto.CreditTransactionDto;
import com.skillswap.backend.backend.service.CreditService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/credits")
public class CreditController {

    private final CreditService creditService;

    public CreditController(CreditService creditService) {
        this.creditService = creditService;
    }

    @GetMapping("/{userId}/balance")
    public CreditBalanceDto balance(@PathVariable Long userId) {
        return creditService.balance(userId);
    }

    @GetMapping("/{userId}/transactions")
    public List<CreditTransactionDto> transactions(@PathVariable Long userId) {
        return creditService.transactions(userId);
    }

    @PostMapping("/purchase")
    public CreditBalanceDto purchase(@RequestBody CreditPurchaseRequest request) {
        return creditService.purchase(
                request == null ? null : request.getUserId(),
                request == null ? null : request.getCredits()
        );
    }
}
