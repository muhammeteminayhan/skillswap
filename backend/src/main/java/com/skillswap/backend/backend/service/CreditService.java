package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.CreditBalanceDto;
import com.skillswap.backend.backend.dto.CreditTransactionDto;
import com.skillswap.backend.backend.model.CreditTransactionEntity;
import com.skillswap.backend.backend.model.CreditWalletEntity;
import com.skillswap.backend.backend.repository.CreditTransactionRepository;
import com.skillswap.backend.backend.repository.CreditWalletRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class CreditService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm");

    private final CreditWalletRepository creditWalletRepository;
    private final CreditTransactionRepository creditTransactionRepository;
    private final CreditConfig creditConfig;

    public CreditService(
            CreditWalletRepository creditWalletRepository,
            CreditTransactionRepository creditTransactionRepository,
            CreditConfig creditConfig
    ) {
        this.creditWalletRepository = creditWalletRepository;
        this.creditTransactionRepository = creditTransactionRepository;
        this.creditConfig = creditConfig;
    }

    public CreditBalanceDto balance(Long userId) {
        CreditWalletEntity wallet = getOrCreateWallet(userId);
        CreditBalanceDto dto = new CreditBalanceDto();
        dto.setUserId(userId);
        dto.setBalance(wallet.getBalance());
        dto.setPricePerCredit(creditConfig.getPricePerCredit());
        dto.setPlatformFeeRate(creditConfig.getPlatformFeeRate());
        return dto;
    }

    public boolean hasEnoughCredits(Long userId, int credits) {
        if (credits <= 0) {
            return true;
        }
        CreditWalletEntity wallet = getOrCreateWallet(userId);
        return wallet.getBalance() >= credits;
    }

    public List<CreditTransactionDto> transactions(Long userId) {
        return creditTransactionRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional
    public CreditBalanceDto purchase(Long userId, Integer credits) {
        if (userId == null) {
            throw new IllegalArgumentException("Kullanici gerekli.");
        }
        if (credits == null || credits <= 0) {
            throw new IllegalArgumentException("Kredi miktari hatali.");
        }
        CreditWalletEntity wallet = getOrCreateWallet(userId);
        int newBalance = wallet.getBalance() + credits;
        wallet.setBalance(newBalance);
        wallet.setUpdatedAt(LocalDateTime.now());
        creditWalletRepository.save(wallet);

        CreditTransactionEntity txn = new CreditTransactionEntity();
        txn.setUserId(userId);
        txn.setType("PURCHASE");
        txn.setCredits(credits);
        txn.setAmountTl(credits * creditConfig.getPricePerCredit());
        txn.setDescription("Kredi satin alimi");
        txn.setCreatedAt(LocalDateTime.now());
        creditTransactionRepository.save(txn);
        return balance(userId);
    }

    @Transactional
    public void chargeListingFeeCredits(Long userId, int credits) {
        if (userId == null || credits <= 0) {
            return;
        }
        CreditWalletEntity wallet = getOrCreateWallet(userId);
        if (wallet.getBalance() < credits) {
            throw new IllegalArgumentException("Ilan vermek icin " + credits + " kredi gerekli. Once kredi tamamla.");
        }
        wallet.setBalance(wallet.getBalance() - credits);
        wallet.setUpdatedAt(LocalDateTime.now());
        creditWalletRepository.save(wallet);

        CreditTransactionEntity txn = new CreditTransactionEntity();
        txn.setUserId(userId);
        txn.setType("LISTING_FEE");
        txn.setCredits(-credits);
        txn.setAmountTl(0);
        txn.setDescription("Ilan komisyonu");
        txn.setCreatedAt(LocalDateTime.now());
        creditTransactionRepository.save(txn);
    }

    @Transactional
    public void settleMatch(Long matchId, Long payerUserId, Long receiverUserId, int credits, String description) {
        if (credits <= 0) {
            return;
        }
        CreditWalletEntity wallet = getOrCreateWallet(payerUserId);
        if (wallet.getBalance() < credits) {
            throw new IllegalArgumentException("Kredi yetersiz. Takas icin kredi tamamlaman gerekiyor.");
        }
        wallet.setBalance(wallet.getBalance() - credits);
        wallet.setUpdatedAt(LocalDateTime.now());
        creditWalletRepository.save(wallet);

        int amountTl = credits * creditConfig.getPricePerCredit();
        int platformFee = (int) Math.round(amountTl * creditConfig.getPlatformFeeRate());
        int payout = amountTl - platformFee;

        CreditTransactionEntity payment = new CreditTransactionEntity();
        payment.setUserId(payerUserId);
        payment.setType("MATCH_PAYMENT");
        payment.setCredits(-credits);
        payment.setAmountTl(amountTl);
        payment.setDescription(description);
        payment.setMatchId(matchId);
        payment.setCreatedAt(LocalDateTime.now());
        creditTransactionRepository.save(payment);

        CreditTransactionEntity income = new CreditTransactionEntity();
        income.setUserId(receiverUserId);
        income.setType("MATCH_INCOME");
        income.setCredits(0);
        income.setAmountTl(payout);
        income.setDescription(description);
        income.setMatchId(matchId);
        income.setCreatedAt(LocalDateTime.now());
        creditTransactionRepository.save(income);
    }

    private CreditWalletEntity getOrCreateWallet(Long userId) {
        return creditWalletRepository.findByUserId(userId)
                .orElseGet(() -> {
                    CreditWalletEntity wallet = new CreditWalletEntity();
                    wallet.setUserId(userId);
                    wallet.setBalance(0);
                    wallet.setUpdatedAt(LocalDateTime.now());
                    return creditWalletRepository.save(wallet);
                });
    }

    private CreditTransactionDto toDto(CreditTransactionEntity entity) {
        CreditTransactionDto dto = new CreditTransactionDto();
        dto.setId(entity.getId());
        dto.setType(entity.getType());
        dto.setCredits(entity.getCredits());
        dto.setAmountTl(entity.getAmountTl());
        dto.setDescription(entity.getDescription() == null ? "" : entity.getDescription());
        dto.setMatchId(entity.getMatchId());
        dto.setCreatedAt(entity.getCreatedAt() == null ? "" : entity.getCreatedAt().format(DATE_FORMATTER));
        return dto;
    }
}
