package com.finapp.dto.request;

import com.finapp.model.MovementType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class TransactionRequest {
    @NotNull
    private UUID accountId;

    private UUID destinationAccountId;
    private UUID contactId;
    private UUID categoryId;

    // On-demand category creation
    private String newCategoryName;

    @NotNull
    @Positive
    private BigDecimal amount;

    @NotNull
    private MovementType type;

    private String description;

    private OffsetDateTime transactionDate;
}
