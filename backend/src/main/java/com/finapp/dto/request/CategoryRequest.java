package com.finapp.dto.request;

import com.finapp.model.MovementType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CategoryRequest {
    @NotBlank
    @Size(max = 50)
    private String name;

    @NotNull
    private MovementType type;
}
