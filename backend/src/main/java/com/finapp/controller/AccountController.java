package com.finapp.controller;

import com.finapp.dto.request.AccountRequest;
import com.finapp.dto.response.ApiResponse;
import com.finapp.service.AccountService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/accounts")
@RequiredArgsConstructor
public class AccountController {

    private final AccountService accountService;

    @PostMapping
    public ResponseEntity<ApiResponse.AccountResponse> create(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody AccountRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(accountService.create(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<ApiResponse.AccountResponse>> findAll(@AuthenticationPrincipal UUID userId) {
        return ResponseEntity.ok(accountService.findAll(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse.AccountResponse> findById(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id) {
        return ResponseEntity.ok(accountService.findById(id, userId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse.AccountResponse> update(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id,
            @Valid @RequestBody AccountRequest request) {
        return ResponseEntity.ok(accountService.update(id, userId, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id) {
        accountService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
