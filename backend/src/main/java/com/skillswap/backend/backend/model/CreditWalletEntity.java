package com.skillswap.backend.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "credit_wallets")
@Data
public class CreditWalletEntity {

    @Id
    private Long userId;

    @Column(nullable = false)
    private Integer balance;

    @Column(nullable = false)
    private LocalDateTime updatedAt;
}
