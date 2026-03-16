package com.finapp.service;

import com.finapp.dto.request.AccountRequest;
import com.finapp.dto.response.ApiResponse;
import com.finapp.exception.NotFoundException;
import com.finapp.model.Account;
import com.finapp.repository.AccountRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AccountService {

    private final AccountRepository accountRepository;

    public ApiResponse.AccountResponse create(UUID userId, AccountRequest request) {
        Account account = Account.builder()
                .userId(userId)
                .name(request.getName())
                .currentBalance(request.getInitialBalance())
                .build();
        return toResponse(accountRepository.save(account));
    }

    public List<ApiResponse.AccountResponse> findAll(UUID userId) {
        return accountRepository.findAllByUserId(userId).stream()
                .map(this::toResponse)
                .toList();
    }

    public ApiResponse.AccountResponse findById(UUID id, UUID userId) {
        return accountRepository.findById(id, userId)
                .map(this::toResponse)
                .orElseThrow(() -> new NotFoundException("Account not found"));
    }

    public ApiResponse.AccountResponse update(UUID id, UUID userId, AccountRequest request) {
        return accountRepository.update(id, userId, request.getName())
                .map(this::toResponse)
                .orElseThrow(() -> new NotFoundException("Account not found"));
    }

    public void delete(UUID id, UUID userId) {
        if (!accountRepository.delete(id, userId)) {
            throw new NotFoundException("Account not found");
        }
    }

    private ApiResponse.AccountResponse toResponse(Account a) {
        return ApiResponse.AccountResponse.builder()
                .id(a.getId())
                .name(a.getName())
                .currentBalance(a.getCurrentBalance())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
