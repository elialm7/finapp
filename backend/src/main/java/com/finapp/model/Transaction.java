package com.finapp.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Transaction {
    private UUID id;
    private UUID userId;
    private UUID accountId;
    private UUID destinationAccountId;
    private UUID contactId;
    private UUID categoryId;
    private BigDecimal amount;
    private MovementType type;
    private String description;
    private OffsetDateTime transactionDate;
    private OffsetDateTime createdAt;
}
