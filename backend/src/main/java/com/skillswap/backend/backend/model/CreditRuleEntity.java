package com.skillswap.backend.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "credit_rules")
@Data
public class CreditRuleEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String category;

    @Column(nullable = false)
    private Integer baseCredit;

    @Column(nullable = false)
    private Integer minCredit;

    @Column(nullable = false)
    private Integer maxCredit;
}
