package com.finapp.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

public class AuthRequest {

    @Data
    public static class Register {
        @NotBlank
        @Email
        private String email;

        @NotBlank
        @Size(min = 6, max = 100)
        private String password;

        private String baseCurrency = "PYG";
    }

    @Data
    public static class Login {
        @NotBlank
        @Email
        private String email;

        @NotBlank
        private String password;
    }
}
