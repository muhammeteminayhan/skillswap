package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.UserProfileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserProfileRepository extends JpaRepository<UserProfileEntity, Long> {

    Optional<UserProfileEntity> findByEmail(String email);

    Optional<UserProfileEntity> findTopByOrderByIdDesc();
}
