package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.dto.AuthLoginRequest;
import com.skillswap.backend.backend.dto.AuthRegisterRequest;
import com.skillswap.backend.backend.dto.AuthResponse;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import org.springframework.stereotype.Service;

import java.util.Locale;
import java.util.UUID;

@Service
public class AuthService {

    private final UserProfileRepository userProfileRepository;

    public AuthService(UserProfileRepository userProfileRepository) {
        this.userProfileRepository = userProfileRepository;
    }

    public AuthResponse register(AuthRegisterRequest request) {
        final String email = normalizeEmail(request.getEmail());
        userProfileRepository.findByEmail(email).ifPresent(existing -> {
            throw new IllegalArgumentException("Bu e-posta zaten kayitli.");
        });

        UserProfileEntity user = new UserProfileEntity();
        user.setId(nextUserId());
        user.setName(request.getName().trim());
        user.setEmail(email);
        user.setPassword(request.getPassword());
        user.setTitle(defaultIfBlank(request.getTitle(), "Yeni Uye"));
        user.setLocation(defaultIfBlank(request.getLocation(), ""));
        user.setBio(defaultIfBlank(request.getBio(), ""));
        user.setTrustScore(50);
        user.setTokenBalance(500);

        UserProfileEntity saved = userProfileRepository.save(user);
        return toResponse(saved);
    }

    public AuthResponse login(AuthLoginRequest request) {
        final String email = normalizeEmail(request.getEmail());
        UserProfileEntity user = userProfileRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("E-posta veya sifre hatali."));

        if (user.getPassword() == null || !user.getPassword().equals(request.getPassword())) {
            throw new IllegalArgumentException("E-posta veya sifre hatali.");
        }

        return toResponse(user);
    }

    private AuthResponse toResponse(UserProfileEntity user) {
        return new AuthResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                "demo-" + user.getId() + "-" + UUID.randomUUID()
        );
    }

    private Long nextUserId() {
        return userProfileRepository.findTopByOrderByIdDesc()
                .map(UserProfileEntity::getId)
                .map(lastId -> lastId + 1)
                .orElse(1L);
    }

    private String normalizeEmail(String rawEmail) {
        return rawEmail == null ? "" : rawEmail.trim().toLowerCase(Locale.ROOT);
    }

    private String defaultIfBlank(String value, String defaultValue) {
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }
        return value.trim();
    }
}
