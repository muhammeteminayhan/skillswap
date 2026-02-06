package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.ListingEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ListingRepository extends JpaRepository<ListingEntity, Long> {

    List<ListingEntity> findAllByOrderByCreatedAtDesc();
}
