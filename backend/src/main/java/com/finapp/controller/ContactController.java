package com.finapp.controller;

import com.finapp.dto.request.ContactRequest;
import com.finapp.dto.response.ApiResponse;
import com.finapp.service.ContactService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/contacts")
@RequiredArgsConstructor
public class ContactController {

    private final ContactService contactService;

    @PostMapping
    public ResponseEntity<ApiResponse.ContactResponse> create(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody ContactRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(contactService.create(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<ApiResponse.ContactResponse>> findAll(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(required = false) String search) {
        if (search != null && !search.isBlank()) {
            return ResponseEntity.ok(contactService.search(userId, search));
        }
        return ResponseEntity.ok(contactService.findAll(userId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse.ContactResponse> findById(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id) {
        return ResponseEntity.ok(contactService.findById(id, userId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse.ContactResponse> update(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id,
            @Valid @RequestBody ContactRequest request) {
        return ResponseEntity.ok(contactService.update(id, userId, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id) {
        contactService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
