package com.skillswap.backend.backend.service;

import java.util.Locale;

public class SkillNormalizer {

    private SkillNormalizer() {
    }

    public static String normalize(String raw) {
        if (raw == null) {
            return "";
        }
        String trimmed = raw.trim();
        if (trimmed.isEmpty()) {
            return "";
        }
        String lower = trimmed.toLowerCase(Locale.forLanguageTag("tr"));

        if (lower.contains("ui") || lower.contains("ux") || lower.contains("tasar")) {
            return "UI_UX";
        }
        if (lower.contains("figma") || lower.contains("design system")) {
            return "UI_UX";
        }
        if (lower.contains("logo") || lower.contains("amblem") || lower.contains("ikon")) {
            return "LOGO_TASARIM";
        }
        if (lower.contains("branding") || lower.contains("brand")) {
            return "LOGO_TASARIM";
        }
        if (lower.contains("mobil") || lower.contains("flutter") || lower.contains("swiftui")) {
            return "MOBIL_UYGULAMA";
        }
        if (lower.contains("frontend") || lower.contains("react") || lower.contains("next")
                || lower.contains("web") || lower.contains("site") || lower.contains("arayuz")
                || lower.contains("tanıtım") || lower.contains("tanitim")) {
            return "WEB_FRONTEND";
        }
        if (lower.contains("backend") || lower.contains("api") || lower.contains("entegrasyon")
                || lower.contains("postgres") || lower.contains("veri model")) {
            return "BACKEND";
        }
        if (lower.contains("klima")) {
            return "KLIMA";
        }
        if (lower.contains("gömülü") || lower.contains("gomulu")) {
            return "GOMULU";
        }
        if (lower.contains("tesisat")) {
            return "TESISAT";
        }
        if (lower.contains("elektrik")) {
            return "ELEKTRIK";
        }
        if (lower.contains("boya") || lower.contains("badana")) {
            return "BOYA";
        }
        if (lower.contains("dogalgaz") || lower.contains("doğalgaz")) {
            return "DOGALGAZ";
        }
        if (lower.contains("kombi")) {
            return "KOMBI";
        }
        if (lower.contains("bilgisayar") || lower.contains("pc")) {
            return "BILGISAYAR";
        }
        if (lower.contains("temizlik")) {
            return "TEMIZLIK";
        }

        return trimmed.toLowerCase(Locale.ROOT);
    }
}
