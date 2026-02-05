package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class MatchCandidate {
    private String name;
    private List<String> skills;
    private int trustScore;
    private int matchScore;
    private int fairnessPercent;
}
