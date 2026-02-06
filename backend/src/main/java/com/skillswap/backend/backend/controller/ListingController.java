package com.skillswap.backend.backend.controller;

import com.skillswap.backend.backend.dto.ListingCreateRequest;
import com.skillswap.backend.backend.dto.ListingResponse;
import com.skillswap.backend.backend.dto.ListingUpdateRequest;
import com.skillswap.backend.backend.service.ListingService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/listings")
public class ListingController {

    private final ListingService listingService;

    public ListingController(ListingService listingService) {
        this.listingService = listingService;
    }

    @GetMapping
    public List<ListingResponse> listAll() {
        return listingService.listAll();
    }

    @GetMapping("/{id}")
    public ListingResponse detail(@PathVariable Long id) {
        return listingService.getById(id);
    }

    @PostMapping
    public ListingResponse create(@Valid @RequestBody ListingCreateRequest request) {
        return listingService.create(request);
    }

    @PutMapping("/{id}")
    public ListingResponse update(
            @PathVariable Long id,
            @Valid @RequestBody ListingUpdateRequest request
    ) {
        return listingService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable Long id,
            @RequestParam Long ownerUserId
    ) {
        listingService.delete(id, ownerUserId);
        return ResponseEntity.noContent().build();
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleIllegalArgument(IllegalArgumentException exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("message", exception.getMessage()));
    }
}
