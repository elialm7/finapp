package com.finapp.service;

import com.finapp.dto.request.TransactionRequest;
import com.finapp.dto.response.ApiResponse;
import com.finapp.exception.BadRequestException;
import com.finapp.exception.NotFoundException;
import com.finapp.model.MovementType;
import com.finapp.model.Transaction;
import com.finapp.repository.AccountRepository;
import com.finapp.repository.CategoryRepository;
import com.finapp.repository.ContactRepository;
import com.finapp.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final ContactRepository contactRepository;
    private final CategoryService categoryService;

    @Transactional
    public ApiResponse.TransactionResponse create(UUID userId, TransactionRequest request) {
        // Validate source account belongs to user
        accountRepository.findById(request.getAccountId(), userId)
                .orElseThrow(() -> new NotFoundException("Source account not found"));

        // Resolve category: on-demand creation if name provided without ID
        UUID categoryId = request.getCategoryId();
        if (categoryId == null && request.getNewCategoryName() != null && !request.getNewCategoryName().isBlank()) {
            ApiResponse.CategoryResponse cat = categoryService.findOrCreate(
                    userId, request.getNewCategoryName(), request.getType());
            categoryId = cat.getId();
        }

        // Validate transfer specifics
        if (request.getType() == MovementType.TRANSFER) {
            if (request.getDestinationAccountId() == null && request.getContactId() == null) {
                throw new BadRequestException("TRANSFER requires a destination account or contact");
            }
            if (request.getDestinationAccountId() != null) {
                accountRepository.findById(request.getDestinationAccountId(), userId)
                        .orElseThrow(() -> new NotFoundException("Destination account not found"));
            }
        }

        OffsetDateTime txDate = request.getTransactionDate() != null
                ? request.getTransactionDate()
                : OffsetDateTime.now();

        Transaction tx = Transaction.builder()
                .userId(userId)
                .accountId(request.getAccountId())
                .destinationAccountId(request.getDestinationAccountId())
                .contactId(request.getContactId())
                .categoryId(categoryId)
                .amount(request.getAmount())
                .type(request.getType())
                .description(request.getDescription())
                .transactionDate(txDate)
                .build();

        Transaction saved = transactionRepository.save(tx);

        // Update balances
        updateBalances(saved);

        return buildResponse(saved);
    }

    private void updateBalances(Transaction tx) {
        switch (tx.getType()) {
            case INCOME -> accountRepository.updateBalance(tx.getAccountId(), tx.getAmount());
            case EXPENSE -> accountRepository.updateBalance(tx.getAccountId(), tx.getAmount().negate());
            case TRANSFER -> {
                accountRepository.updateBalance(tx.getAccountId(), tx.getAmount().negate());
                if (tx.getDestinationAccountId() != null) {
                    accountRepository.updateBalance(tx.getDestinationAccountId(), tx.getAmount());
                }
            }
        }
    }

    public ApiResponse.TransactionResponse findById(UUID id, UUID userId) {
        return transactionRepository.findById(id, userId)
                .map(this::buildResponse)
                .orElseThrow(() -> new NotFoundException("Transaction not found"));
    }

    public Map<String, Object> findAll(UUID userId, OffsetDateTime from, OffsetDateTime to, int page, int size) {
        int offset = page * size;
        List<ApiResponse.TransactionResponse> items = transactionRepository
                .findByUserAndDateRange(userId, from, to, size, offset)
                .stream().map(this::buildResponse).toList();
        int total = transactionRepository.countByUserAndDateRange(userId, from, to);
        return Map.of("items", items, "total", total, "page", page, "size", size);
    }

    @Transactional
    public void delete(UUID id, UUID userId) {
        Transaction tx = transactionRepository.findById(id, userId)
                .orElseThrow(() -> new NotFoundException("Transaction not found"));
        // Reverse balance updates
        reverseBalances(tx);
        transactionRepository.delete(id, userId);
    }

    private void reverseBalances(Transaction tx) {
        switch (tx.getType()) {
            case INCOME -> accountRepository.updateBalance(tx.getAccountId(), tx.getAmount().negate());
            case EXPENSE -> accountRepository.updateBalance(tx.getAccountId(), tx.getAmount());
            case TRANSFER -> {
                accountRepository.updateBalance(tx.getAccountId(), tx.getAmount());
                if (tx.getDestinationAccountId() != null) {
                    accountRepository.updateBalance(tx.getDestinationAccountId(), tx.getAmount().negate());
                }
            }
        }
    }

    public ApiResponse.DashboardSummary getDashboard(UUID userId, OffsetDateTime from, OffsetDateTime to) {
        Map<String, BigDecimal> summary = transactionRepository.getSummary(userId, from, to);
        BigDecimal income = summary.get("totalIncome");
        BigDecimal expenses = summary.get("totalExpenses");

        List<ApiResponse.CategorySummary> topExpenses = transactionRepository
                .getTopCategories(userId, from, to, MovementType.EXPENSE, 5)
                .stream().map(row -> ApiResponse.CategorySummary.builder()
                        .categoryName((String) row.get("category_name"))
                        .total((BigDecimal) row.get("total"))
                        .count(((Number) row.get("count")).longValue())
                        .build())
                .toList();

        List<ApiResponse.CategorySummary> topIncome = transactionRepository
                .getTopCategories(userId, from, to, MovementType.INCOME, 5)
                .stream().map(row -> ApiResponse.CategorySummary.builder()
                        .categoryName((String) row.get("category_name"))
                        .total((BigDecimal) row.get("total"))
                        .count(((Number) row.get("count")).longValue())
                        .build())
                .toList();

        return ApiResponse.DashboardSummary.builder()
                .totalIncome(income)
                .totalExpenses(expenses)
                .netBalance(income.subtract(expenses))
                .totalTransferred(summary.get("totalTransferred"))
                .topExpenseCategories(topExpenses)
                .topIncomeCategories(topIncome)
                .build();
    }

    private ApiResponse.TransactionResponse buildResponse(Transaction tx) {
        ApiResponse.TransactionResponse.TransactionResponseBuilder builder = ApiResponse.TransactionResponse.builder()
                .id(tx.getId())
                .accountId(tx.getAccountId())
                .destinationAccountId(tx.getDestinationAccountId())
                .contactId(tx.getContactId())
                .categoryId(tx.getCategoryId())
                .amount(tx.getAmount())
                .type(tx.getType())
                .description(tx.getDescription())
                .transactionDate(tx.getTransactionDate())
                .createdAt(tx.getCreatedAt());

        // Enrich with names via lazy look-up (acceptable for read path)
        if (tx.getCategoryId() != null) {
            categoryRepository.findById(tx.getCategoryId(), tx.getUserId())
                    .ifPresent(c -> builder.categoryName(c.getName()));
        }
        if (tx.getContactId() != null) {
            contactRepository.findById(tx.getContactId(), tx.getUserId())
                    .ifPresent(c -> builder.contactName(c.getName()));
        }

        return builder.build();
    }
}
