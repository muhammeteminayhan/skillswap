package com.skillswap.backend.backend.service;

import com.skillswap.backend.backend.model.ChatMessageEntity;
import com.skillswap.backend.backend.model.CreditRuleEntity;
import com.skillswap.backend.backend.model.ListingEntity;
import com.skillswap.backend.backend.model.UserProfileEntity;
import com.skillswap.backend.backend.model.UserSkillEntity;
import com.skillswap.backend.backend.repository.ChatMessageRepository;
import com.skillswap.backend.backend.repository.CreditRuleRepository;
import com.skillswap.backend.backend.repository.ListingRepository;
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
    private final ListingRepository listingRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final SwapRequestService swapRequestService;
    private final CreditRuleRepository creditRuleRepository;

    public SkillSwapDataSeeder(
            UserProfileRepository userProfileRepository,
            UserSkillRepository userSkillRepository,
            ListingRepository listingRepository,
            ChatMessageRepository chatMessageRepository,
            SwapRequestService swapRequestService,
            CreditRuleRepository creditRuleRepository
    ) {
        this.userProfileRepository = userProfileRepository;
        this.userSkillRepository = userSkillRepository;
        this.listingRepository = listingRepository;
        this.chatMessageRepository = chatMessageRepository;
        this.swapRequestService = swapRequestService;
        this.creditRuleRepository = creditRuleRepository;
    }

    @Override
    public void run(String... args) {
        seedCreditRules();
        if (userProfileRepository.count() > 0) {
            swapRequestService.rebuildAll();
            return;
        }

        saveUser(1L, "Gokhan", "gokhan@skillswap.demo", "demo123", "Elektrik Ustasi", "Kadikoy", 50, "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80", "Elektrik tesisati, priz ve aydinlatma isleri yapiyorum.");
        saveUser(2L, "Tuncay", "tuncay@skillswap.demo", "demo123", "Tesisat Ustasi", "Uskudar", 50, "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=400&q=80", "Su tesisati ve kombi baglantilari.");
        saveUser(3L, "Merve", "merve@skillswap.demo", "demo123", "Dogalgaz Teknisyeni", "Besiktas", 50, "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=400&q=80", "Kombi bakim ve dogalgaz hatti kontrolu.");
        saveUser(4L, "Selin", "selin@skillswap.demo", "demo123", "PC Teknik Servis", "Kadikoy", 50, "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=400&q=80", "Laptop format, donanim yukseltme.");
        saveUser(5L, "Ahmet", "ahmet@skillswap.demo", "demo123", "Boya Ustasi", "Atasehir", 50, "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=400&q=80", "Ic cephe boya ve alci isleri.");

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

        swapRequestService.rebuildAll();

        seedListings();
        seedMessages();
    }

    private void seedCreditRules() {
        if (creditRuleRepository.count() > 0) {
            return;
        }
        saveRule("UI_UX", 80, 70, 95);
        saveRule("LOGO_TASARIM", 75, 60, 90);
        saveRule("MOBIL_UYGULAMA", 120, 100, 140);
        saveRule("WEB_FRONTEND", 90, 75, 110);
        saveRule("BACKEND", 110, 90, 135);
        saveRule("KLIMA", 75, 60, 90);
        saveRule("GOMULU", 120, 100, 145);
        saveRule("TESISAT", 95, 80, 120);
        saveRule("ELEKTRIK", 90, 80, 120);
        saveRule("BOYA", 75, 60, 95);
        saveRule("DOGALGAZ", 90, 75, 115);
        saveRule("KOMBI", 85, 70, 110);
        saveRule("BILGISAYAR", 80, 65, 100);
        saveRule("TEMIZLIK", 60, 50, 80);
    }

    private void saveRule(String category, int base, int min, int max) {
        CreditRuleEntity rule = new CreditRuleEntity();
        rule.setCategory(category);
        rule.setBaseCredit(base);
        rule.setMinCredit(min);
        rule.setMaxCredit(max);
        creditRuleRepository.save(rule);
    }

    private void saveUser(
            Long id,
            String name,
            String email,
            String password,
            String title,
            String location,
            Integer trustScore,
            String photoUrl,
            String bio
    ) {
        UserProfileEntity user = new UserProfileEntity();
        user.setId(id);
        user.setName(name);
        user.setEmail(email);
        user.setPassword(password);
        user.setTitle(title);
        user.setLocation(location);
        user.setTrustScore(trustScore);
        user.setBoost(false);
        user.setPhotoUrl(photoUrl);
        user.setBio(bio);
        userProfileRepository.save(user);
    }

    private void seedSkills(Long userId, List<String> offers, List<String> wants) {
        for (String offer : offers) {
            UserSkillEntity skill = new UserSkillEntity();
            skill.setUserId(userId);
            skill.setSkillName(offer);
            skill.setNormalizedSkill(SkillNormalizer.normalize(offer));
            skill.setSkillDescription("Demo yetenek açıklaması: " + offer);
            skill.setSkillType("OFFER");
            userSkillRepository.save(skill);
        }

        for (String want : wants) {
            UserSkillEntity skill = new UserSkillEntity();
            skill.setUserId(userId);
            skill.setSkillName(want);
            skill.setNormalizedSkill(SkillNormalizer.normalize(want));
            skill.setSkillDescription("Demo ihtiyaç açıklaması: " + want);
            skill.setSkillType("WANT");
            userSkillRepository.save(skill);
        }
    }

    private void seedListings() {
        if (listingRepository.count() > 0) {
            return;
        }

        saveListing(
                1L,
                "Gokhan",
                "Elektrik Ustasi",
                "Daire ici priz ve aydinlatma yenileme",
                "Ev ici elektrik tesisati, sigorta degisimi ve avize montaji yapabilirim.",
                "https://images.unsplash.com/photo-1581578731548-c64695cc6952?auto=format&fit=crop&w=1200&q=80",
                "0555 111 22 33",
                "Kadikoy"
        );
        saveListing(
                2L,
                "Tuncay",
                "Tesisat Ustasi",
                "Su kacagi ve musluk tamiri",
                "Banyo ve mutfak icin musluk degisimi, su kacagi bulma ve onarim hizmeti.",
                "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=1200&q=80",
                "0555 222 33 44",
                "Uskudar"
        );
        saveListing(
                3L,
                "Merve",
                "Keman Ogretmeni",
                "Baslangic seviye keman dersi",
                "Hafta ici aksam birebir keman dersi veriyorum. Nota temeli ve teknik calisma.",
                "https://images.unsplash.com/photo-1514119412350-e174d90d280e?auto=format&fit=crop&w=1200&q=80",
                "0555 333 44 55",
                "Besiktas"
        );
    }

    private void saveListing(
            Long ownerUserId,
            String ownerName,
            String profession,
            String title,
            String description,
            String imageUrl,
            String phone,
            String location
    ) {
        ListingEntity listing = new ListingEntity();
        listing.setOwnerUserId(ownerUserId);
        listing.setOwnerName(ownerName);
        listing.setProfession(profession);
        listing.setTitle(title);
        listing.setDescription(description);
        listing.setImageUrl(imageUrl);
        listing.setPhone(phone);
        listing.setLocation(location);
        listingRepository.save(listing);
    }

    private void seedMessages() {
        if (chatMessageRepository.count() > 0) {
            return;
        }
        saveMessage(1L, 2L, "Merhaba, tesisat isi icin ne zaman musaitsin?");
        saveMessage(2L, 1L, "Yarin 18:30 uygun. Elektrik isi icin de konusalim.");
        saveMessage(1L, 2L, "Harika, konum ve detaylari yaziyorum.");
    }

    private void saveMessage(Long fromUserId, Long toUserId, String body) {
        ChatMessageEntity message = new ChatMessageEntity();
        message.setSenderUserId(fromUserId);
        message.setReceiverUserId(toUserId);
        message.setBody(body);
        message.setRead(false);
        chatMessageRepository.save(message);
    }
}
