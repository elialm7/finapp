package com.finapp.service;

import com.finapp.dto.request.ContactRequest;
import com.finapp.dto.response.ApiResponse;
import com.finapp.exception.NotFoundException;
import com.finapp.model.Contact;
import com.finapp.repository.ContactRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ContactService {

    private final ContactRepository contactRepository;

    public ApiResponse.ContactResponse create(UUID userId, ContactRequest request) {
        Contact contact = Contact.builder()
                .userId(userId)
                .name(request.getName())
                .description(request.getDescription())
                .build();
        return toResponse(contactRepository.save(contact));
    }

    public List<ApiResponse.ContactResponse> findAll(UUID userId) {
        return contactRepository.findAllByUserId(userId).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<ApiResponse.ContactResponse> search(UUID userId, String name) {
        return contactRepository.searchByName(userId, name).stream()
                .map(this::toResponse)
                .toList();
    }

    public ApiResponse.ContactResponse findById(UUID id, UUID userId) {
        return contactRepository.findById(id, userId)
                .map(this::toResponse)
                .orElseThrow(() -> new NotFoundException("Contact not found"));
    }

    public ApiResponse.ContactResponse update(UUID id, UUID userId, ContactRequest request) {
        return contactRepository.update(id, userId, request.getName(), request.getDescription())
                .map(this::toResponse)
                .orElseThrow(() -> new NotFoundException("Contact not found"));
    }

    public void delete(UUID id, UUID userId) {
        if (!contactRepository.delete(id, userId)) {
            throw new NotFoundException("Contact not found");
        }
    }

    private ApiResponse.ContactResponse toResponse(Contact c) {
        return ApiResponse.ContactResponse.builder()
                .id(c.getId())
                .name(c.getName())
                .description(c.getDescription())
                .createdAt(c.getCreatedAt())
                .build();
    }
}
