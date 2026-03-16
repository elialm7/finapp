package com.finapp.controller;

import com.finapp.dto.request.CategoryRequest;
import com.finapp.dto.response.ApiResponse;
import com.finapp.model.MovementType;
import com.finapp.service.CategoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class CategoryController {

    private final CategoryService categoryService;

    @PostMapping
    public ResponseEntity<ApiResponse.CategoryResponse> create(
            @AuthenticationPrincipal UUID userId,
            @Valid @RequestBody CategoryRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(categoryService.create(userId, request));
    }

    @GetMapping
    public ResponseEntity<List<ApiResponse.CategoryResponse>> findAll(
            @AuthenticationPrincipal UUID userId,
            @RequestParam(required = false) MovementType type) {
        if (type != null) {
            return ResponseEntity.ok(categoryService.findByType(userId, type));
        }
        return ResponseEntity.ok(categoryService.findAll(userId));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse.CategoryResponse> update(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id,
            @Valid @RequestBody CategoryRequest request) {
        return ResponseEntity.ok(categoryService.update(id, userId, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @AuthenticationPrincipal UUID userId,
            @PathVariable UUID id) {
        categoryService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }
}
