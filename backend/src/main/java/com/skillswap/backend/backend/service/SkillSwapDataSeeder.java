package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.model.UserSkillEntity;
import com.skillswap.backend.backend.repository.UserProfileRepository;
import com.skillswap.backend.backend.repository.UserSkillRepository;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@ConditionalOnProperty(name = "app.seed.enabled", havingValue = "true")
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

        saveUser(1L, "Gokhan", "gokhan@skillswap.demo", "demo123", "Elektrik Ustasi", "Kadikoy", 88, 1320, "Elektrik tesisati, priz ve aydinlatma isleri yapiyorum.");
        saveUser(2L, "Tuncay", "tuncay@skillswap.demo", "demo123", "Tesisat Ustasi", "Uskudar", 91, 1450, "Su tesisati ve kombi baglantilari.");
        saveUser(3L, "Merve", "merve@skillswap.demo", "demo123", "Dogalgaz Teknisyeni", "Besiktas", 86, 1180, "Kombi bakim ve dogalgaz hatti kontrolu.");
        saveUser(4L, "Selin", "selin@skillswap.demo", "demo123", "PC Teknik Servis", "Kadikoy", 84, 960, "Laptop format, donanim yukseltme.");
        saveUser(5L, "Ahmet", "ahmet@skillswap.demo", "demo123", "Boya Ustasi", "Atasehir", 80, 840, "Ic cephe boya ve alci isleri.");

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

    private void saveUser(Long id, String name, String email, String password, String title, String location, Integer trustScore, Integer tokenBalance, String bio) {
        UserProfileEntity user = new UserProfileEntity();
        user.setId(id);
        user.setName(name);
        user.setEmail(email);
        user.setPassword(password);
        user.setTitle(title);
        user.setLocation(location);
        user.setTrustScore(trustScore);
        user.setTokenBalance(tokenBalance);
        user.setBio(bio);
        userProfileRepository.save(user);
    }

    private void seedSkills(Long userId, List<String> offers, List<String> wants) {
        for (String offer : offers) {
            UserSkillEntity skill = new UserSkillEntity();
            skill.setUserId(userId);
            skill.setSkillName(offer);
            skill.setSkillDescription("Demo yetenek açıklaması: " + offer);
            skill.setSkillType("OFFER");
            userSkillRepository.save(skill);
        }

        for (String want : wants) {
            UserSkillEntity skill = new UserSkillEntity();
            skill.setUserId(userId);
            skill.setSkillName(want);
            skill.setSkillDescription("Demo ihtiyaç açıklaması: " + want);
            skill.setSkillType("WANT");
            userSkillRepository.save(skill);
        }
    }
}
