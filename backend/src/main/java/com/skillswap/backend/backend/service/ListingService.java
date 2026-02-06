package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.ListingCreateRequest;
import com.skillswap.backend.backend.dto.ListingResponse;
import com.skillswap.backend.backend.dto.ListingUpdateRequest;
import com.skillswap.backend.backend.model.ListingEntity;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.ListingRepository;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class ListingService {

    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm");

    private final ListingRepository listingRepository;
    private final UserProfileRepository userProfileRepository;

    public ListingService(ListingRepository listingRepository, UserProfileRepository userProfileRepository) {
        this.listingRepository = listingRepository;
        this.userProfileRepository = userProfileRepository;
    }

    public List<ListingResponse> listAll() {
        return listingRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(this::toResponse)
                .toList();
    }

    public ListingResponse getById(Long id) {
        ListingEntity entity = listingRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Ilan bulunamadi."));
        return toResponse(entity);
    }

    @Transactional
    public ListingResponse create(ListingCreateRequest request) {
        UserProfileEntity owner = userProfileRepository.findById(request.getOwnerUserId())
                .orElseThrow(() -> new IllegalArgumentException("Ilan sahibi kullanici bulunamadi."));

        ListingEntity entity = new ListingEntity();
        entity.setOwnerUserId(owner.getId());
        entity.setOwnerName(owner.getName());
        entity.setProfession(request.getProfession().trim());
        entity.setTitle(request.getTitle().trim());
        entity.setDescription(request.getDescription().trim());
        entity.setPhone(request.getPhone().trim());
        entity.setLocation(request.getLocation().trim());
        entity.setImageUrl(cleanImageUrl(request.getImageUrl()));

        return toResponse(listingRepository.save(entity));
    }

    @Transactional
    public ListingResponse update(Long listingId, ListingUpdateRequest request) {
        ListingEntity entity = listingRepository.findById(listingId)
                .orElseThrow(() -> new IllegalArgumentException("Ilan bulunamadi."));
        if (request == null || request.getOwnerUserId() == null) {
            throw new IllegalArgumentException("Kullanici bilgisi gerekli.");
        }
        if (!request.getOwnerUserId().equals(entity.getOwnerUserId())) {
            throw new IllegalArgumentException("Bu ilani guncelleyemezsiniz.");
        }
        entity.setProfession(request.getProfession().trim());
        entity.setTitle(request.getTitle().trim());
        entity.setDescription(request.getDescription().trim());
        entity.setPhone(request.getPhone().trim());
        entity.setLocation(request.getLocation().trim());
        if (request.getImageUrl() != null && !request.getImageUrl().isBlank()) {
            entity.setImageUrl(request.getImageUrl().trim());
        }

        return toResponse(listingRepository.save(entity));
    }

    @Transactional
    public void delete(Long listingId, Long ownerUserId) {
        ListingEntity entity = listingRepository.findById(listingId)
                .orElseThrow(() -> new IllegalArgumentException("Ilan bulunamadi."));
        if (ownerUserId == null || !ownerUserId.equals(entity.getOwnerUserId())) {
            throw new IllegalArgumentException("Bu ilani silemezsiniz.");
        }
        listingRepository.delete(entity);
    }

    private String cleanImageUrl(String imageUrl) {
        if (imageUrl == null || imageUrl.isBlank()) {
            return "https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=1200&q=80";
        }
        return imageUrl.trim();
    }

    private ListingResponse toResponse(ListingEntity entity) {
        ListingResponse response = new ListingResponse();
        response.setId(entity.getId());
        response.setOwnerUserId(entity.getOwnerUserId());
        response.setOwnerName(entity.getOwnerName());
        response.setProfession(entity.getProfession());
        response.setTitle(entity.getTitle());
        response.setDescription(entity.getDescription());
        response.setImageUrl(entity.getImageUrl());
        response.setPhone(entity.getPhone());
        response.setLocation(entity.getLocation());
        response.setCreatedAt(entity.getCreatedAt() == null ? "" : entity.getCreatedAt().format(DATE_FORMATTER));
        return response;
    }
}
