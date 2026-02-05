package com.skillswap.backend.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class AuthRegisterRequest {

    @NotBlank(message = "Ad zorunludur.")
    private String name;

    @Email(message = "Gecerli bir e-posta girin.")
    @NotBlank(message = "E-posta zorunludur.")
    private String email;

    @Size(min = 6, message = "Sifre en az 6 karakter olmalidir.")
    private String password;

    private String title;
    private String location;
    private String bio;
}
