package com.skillswap.backend.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "credit_transactions")
@Data
public class CreditTransactionEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false)
    private String type;

    @Column(nullable = false)
    private Integer credits;

    @Column(nullable = false)
    private Integer amountTl;

    @Column(length = 600)
    private String description;

    @Column
    private Long matchId;

    @Column(nullable = false)
    private LocalDateTime createdAt;
}
