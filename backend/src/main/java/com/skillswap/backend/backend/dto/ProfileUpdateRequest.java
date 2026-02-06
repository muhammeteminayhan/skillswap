package com.skillswap.backend.backend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ProfileUpdateRequest {

    @NotBlank
    private String name;

    @NotBlank
    private String title;

    @NotBlank
    private String location;

    private String bio;

    private String photoUrl;
}
