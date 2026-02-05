package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.model.UserSkillEntity;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import com.skillswap.backend.backend.repository.UserSkillRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class SkillSwapDataSeeder implements CommandLineRunner {

    private final UserProfileRepository userProfileRepository;
    private final UserSkillRepository userSkillRepository;

    public SkillSwapDataSeeder(UserProfileRepository userProfileRepository, UserSkillRepository userSkillRepository) {
        this.userProfileRepository = userProfileRepository;
        this.userSkillRepository = userSkillRepository;
    }

    @Override
    public void run(String... args) {
        if (userProfileRepository.count() > 0) {
            return;
        }

        saveUser(1L, "Gökhan", "Elektrik Ustası", "Kadıköy", 88, "Elektrik tesisatı, priz ve aydınlatma işleri yapıyorum.");
        saveUser(2L, "Tuncay", "Tesisat Ustası", "Üsküdar", 91, "Su tesisatı ve kombi bağlantıları.");
        saveUser(3L, "Merve", "Doğalgaz Teknisyeni", "Beşiktaş", 86, "Kombi bakım ve doğalgaz hattı kontrolü.");
        saveUser(4L, "Selin", "PC Teknik Servis", "Kadıköy", 84, "Laptop format, donanım yükseltme.");
        saveUser(5L, "Ahmet", "Boya Ustası", "Ataşehir", 80, "İç cephe boya ve alçı işleri.");

        seedSkills(1L,
                List.of("Elektrik - priz", "Elektrik - avize montajı", "Elektrik - sigorta"),
                List.of("Tesisat - su kaçağı", "Doğalgaz - kombi bakımı"));
        seedSkills(2L,
                List.of("Tesisat - su kaçağı", "Tesisat - musluk tamiri"),
                List.of("Elektrik - priz", "Elektrik - sigorta"));
        seedSkills(3L,
                List.of("Doğalgaz - kombi bakımı", "Petek temizliği"),
                List.of("Elektrik - avize montajı", "PC tamir"));
        seedSkills(4L,
                List.of("PC tamir", "Laptop format", "Yazıcı kurulumu"),
                List.of("Elektrik - priz", "Boya - iç cephe"));
        seedSkills(5L,
                List.of("Boya - iç cephe", "Alçı - duvar düzeltme"),
                List.of("Doğalgaz - kombi bakımı", "Elektrik - priz"));
    }

    private void saveUser(Long id, String name, String title, String location, Integer trustScore, String bio) {
        UserProfileEntity user = new UserProfileEntity();
        user.setId(id);
        user.setName(name);
        user.setTitle(title);
        user.setLocation(location);
        user.setTrustScore(trustScore);
        user.setBio(bio);
        userProfileRepository.save(user);
    }

    private void seedSkills(Long userId, List<String> offers, List<String> wants) {
        for (String offer : offers) {
            UserSkillEntity skill = new UserSkillEntity();
            skill.setUserId(userId);
            skill.setSkillName(offer);
            skill.setSkillType("OFFER");
            userSkillRepository.save(skill);
        }

        for (String want : wants) {
            UserSkillEntity skill = new UserSkillEntity();
            skill.setUserId(userId);
            skill.setSkillName(want);
            skill.setSkillType("WANT");
            userSkillRepository.save(skill);
        }
    }
}
