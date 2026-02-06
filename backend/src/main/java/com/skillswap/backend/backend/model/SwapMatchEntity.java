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
@Table(name = "swap_matches")
@Data
public class SwapMatchEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userAId;

    @Column(nullable = false)
    private Long userBId;

    @Column(nullable = false)
    private Long requestAId;

    @Column(nullable = false)
    private Long requestBId;

    @Column(nullable = false)
    private String requestAWanted;

    @Column(nullable = false)
    private String requestAOffered;

    @Column(nullable = false)
    private String requestBWanted;

    @Column(nullable = false)
    private String requestBOffered;

    @Column(nullable = false)
    private Boolean acceptedByA;

    @Column(nullable = false)
    private Boolean acceptedByB;

    @Column(nullable = false)
    private Boolean doneByA;

    @Column(nullable = false)
    private Boolean doneByB;

    @Column(nullable = false)
    private String status;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;
}
