package com.skillswap.backend.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ListingUpdateRequest {

    @NotNull
    private Long ownerUserId;

    @NotBlank
    private String profession;

    @NotBlank
    private String title;

    @NotBlank
    private String description;

    @NotBlank
    private String phone;

    @NotBlank
    private String location;

    private String imageUrl;
}
