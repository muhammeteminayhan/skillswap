package com.skillswap.backend.backend.repository;

import com.skillswap.backend.backend.model.UserSkillEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserSkillRepository extends JpaRepository<UserSkillEntity, Long> {
    List<UserSkillEntity> findByUserId(Long userId);

    List<UserSkillEntity> findByUserIdAndSkillType(Long userId, String skillType);

    boolean existsByUserIdAndSkillTypeAndSkillNameIgnoreCase(Long userId, String skillType, String skillName);

    List<UserSkillEntity> findBySkillType(String skillType);

    void deleteByUserId(Long userId);
}
