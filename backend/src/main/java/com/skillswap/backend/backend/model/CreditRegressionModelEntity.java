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
@Table(name = "credit_regression_models")
@Data
public class CreditRegressionModelEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Double intercept;

    @Column(nullable = false)
    private Double hours;

    @Column(nullable = false)
    private Double difficulty;

    @Column(nullable = false)
    private Double risk;

    @Column(nullable = false)
    private Double scope;

    @Column(nullable = false)
    private Double trust;

    @Column(nullable = false)
    private Integer minCredit;

    @Column(nullable = false)
    private Integer maxCredit;

    @Column(length = 120)
    private String datasetName;

    @Column(nullable = false)
    private LocalDateTime trainedAt;
}
