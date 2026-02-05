package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.UserProfileEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserProfileRepository extends JpaRepository<UserProfileEntity, Long> {
}
