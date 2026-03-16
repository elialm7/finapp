package com.finapp.service;

import com.finapp.dto.request.CategoryRequest;
import com.finapp.dto.response.ApiResponse;
import com.finapp.exception.NotFoundException;
import com.finapp.model.Category;
import com.finapp.model.MovementType;
import com.finapp.repository.CategoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;

    public ApiResponse.CategoryResponse create(UUID userId, CategoryRequest request) {
        Category category = Category.builder()
                .userId(userId)
                .name(request.getName())
                .type(request.getType())
                .build();
        return toResponse(categoryRepository.save(category));
    }

    /**
     * On-demand: find or create a category by name + type.
     */
    public ApiResponse.CategoryResponse findOrCreate(UUID userId, String name, MovementType type) {
        return categoryRepository.findByNameAndType(name, type, userId)
                .map(this::toResponse)
                .orElseGet(() -> {
                    Category category = Category.builder()
                            .userId(userId)
                            .name(name)
                            .type(type)
                            .build();
                    return toResponse(categoryRepository.save(category));
                });
    }

    public List<ApiResponse.CategoryResponse> findAll(UUID userId) {
        return categoryRepository.findAllByUserId(userId).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<ApiResponse.CategoryResponse> findByType(UUID userId, MovementType type) {
        return categoryRepository.findAllByUserIdAndType(userId, type).stream()
                .map(this::toResponse)
                .toList();
    }

    public ApiResponse.CategoryResponse update(UUID id, UUID userId, CategoryRequest request) {
        return categoryRepository.update(id, userId, request.getName())
                .map(this::toResponse)
                .orElseThrow(() -> new NotFoundException("Category not found"));
    }

    public void delete(UUID id, UUID userId) {
        if (!categoryRepository.delete(id, userId)) {
            throw new NotFoundException("Category not found");
        }
    }

    private ApiResponse.CategoryResponse toResponse(Category c) {
        return ApiResponse.CategoryResponse.builder()
                .id(c.getId())
                .name(c.getName())
                .type(c.getType())
                .build();
    }
}
