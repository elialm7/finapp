package com.finapp.dto.response;

import com.finapp.model.MovementType;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ApiResponse {

    @Data
    @Builder
    public static class Auth {
        private String token;
        private String email;
        private String baseCurrency;
    }

    @Data
    @Builder
    public static class AccountResponse {
        private UUID id;
        private String name;
        private BigDecimal currentBalance;
        private OffsetDateTime createdAt;
    }

    @Data
    @Builder
    public static class CategoryResponse {
        private UUID id;
        private String name;
        private MovementType type;
    }

    @Data
    @Builder
    public static class ContactResponse {
        private UUID id;
        private String name;
        private String description;
        private OffsetDateTime createdAt;
    }

    @Data
    @Builder
    public static class TransactionResponse {
        private UUID id;
        private UUID accountId;
        private String accountName;
        private UUID destinationAccountId;
        private String destinationAccountName;
        private UUID contactId;
        private String contactName;
        private UUID categoryId;
        private String categoryName;
        private BigDecimal amount;
        private MovementType type;
        private String description;
        private OffsetDateTime transactionDate;
        private OffsetDateTime createdAt;
    }

    @Data
    @Builder
    public static class DashboardSummary {
        private BigDecimal totalIncome;
        private BigDecimal totalExpenses;
        private BigDecimal netBalance;
        private BigDecimal totalTransferred;
        private java.util.List<CategorySummary> topExpenseCategories;
        private java.util.List<CategorySummary> topIncomeCategories;
    }

    @Data
    @Builder
    public static class CategorySummary {
        private String categoryName;
        private BigDecimal total;
        private long count;
    }

    @Data
    @Builder
    public static class ErrorResponse {
        private int status;
        private String message;
        private java.util.Map<String, String> errors;
    }
}
