package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class ProfileResponse {
    private Long userId;
    private String name;
    private String title;
    private String location;
    private Integer trustScore;
    private String bio;
}
