package com.finapp.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class AccountRequest {
    @NotBlank
    @Size(max = 100)
    private String name;

    private BigDecimal initialBalance = BigDecimal.ZERO;
}
