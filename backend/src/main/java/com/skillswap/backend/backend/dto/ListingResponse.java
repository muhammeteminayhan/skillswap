package com.skillswap.backend.backend.dto;

import lombok.Data;

@Data
public class ListingResponse {

    private Long id;
    private Long ownerUserId;
    private String ownerName;
    private String profession;
    private String title;
    private String description;
    private String imageUrl;
    private String phone;
    private String location;
    private String createdAt;
}
