package com.skillswap.backend.backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "credit_profiles")
@Data
public class CreditProfileEntity {

    @Id
    @Column(nullable = false, unique = true)
    private String category;

    @Column(nullable = false)
    private Double hours;

    @Column(nullable = false)
    private Integer difficulty;

    @Column(nullable = false)
    private Integer risk;

    @Column(nullable = false)
    private Double scope;
}
