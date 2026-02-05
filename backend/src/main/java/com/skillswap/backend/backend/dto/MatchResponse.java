package com.skillswap.backend.backend.dto;

import lombok.Data;

import java.util.List;

@Data
public class MatchResponse {
    private List<MatchCandidate> candidates;
}
