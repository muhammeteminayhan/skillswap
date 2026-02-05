package com.skillswap.backend.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AuthLoginRequest {

    @Email(message = "Gecerli bir e-posta girin.")
    @NotBlank(message = "E-posta zorunludur.")
    private String email;

    @NotBlank(message = "Sifre zorunludur.")
    private String password;
}
