package com.finapp.service;

import com.finapp.dto.request.AuthRequest;
import com.finapp.dto.response.ApiResponse;
import com.finapp.exception.BadRequestException;
import com.finapp.exception.ConflictException;
import com.finapp.model.User;
import com.finapp.repository.UserRepository;
import com.finapp.security.JwtUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtils jwtUtils;

    public ApiResponse.Auth register(AuthRequest.Register request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ConflictException("Email already registered");
        }
        User user = User.builder()
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .baseCurrency(request.getBaseCurrency())
                .build();
        User saved = userRepository.save(user);
        String token = jwtUtils.generateToken(saved.getId(), saved.getEmail());
        return ApiResponse.Auth.builder()
                .token(token)
                .email(saved.getEmail())
                .baseCurrency(saved.getBaseCurrency())
                .build();
    }

    public ApiResponse.Auth login(AuthRequest.Login request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("Invalid email or password"));
        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadRequestException("Invalid email or password");
        }
        String token = jwtUtils.generateToken(user.getId(), user.getEmail());
        return ApiResponse.Auth.builder()
                .token(token)
                .email(user.getEmail())
                .baseCurrency(user.getBaseCurrency())
                .build();
    }
}
