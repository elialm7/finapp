package com.finapp.repository;

import com.finapp.model.User;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class UserRepository {

    private final JdbcTemplate jdbc;

    private final RowMapper<User> userRowMapper = (rs, rowNum) -> User.builder()
            .id(rs.getObject("id", UUID.class))
            .email(rs.getString("email"))
            .passwordHash(rs.getString("password_hash"))
            .baseCurrency(rs.getString("base_currency"))
            .createdAt(rs.getObject("created_at", java.time.OffsetDateTime.class))
            .build();

    public User save(User user) {
        String sql = """
                INSERT INTO users (id, email, password_hash, base_currency)
                VALUES (uuid_generate_v4(), ?, ?, ?)
                RETURNING *
                """;
        return jdbc.queryForObject(sql, userRowMapper,
                user.getEmail(), user.getPasswordHash(), user.getBaseCurrency());
    }

    public Optional<User> findByEmail(String email) {
        String sql = "SELECT * FROM users WHERE email = ?";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, userRowMapper, email));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public Optional<User> findById(UUID id) {
        String sql = "SELECT * FROM users WHERE id = ?";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, userRowMapper, id));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public boolean existsByEmail(String email) {
        String sql = "SELECT COUNT(*) FROM users WHERE email = ?";
        Integer count = jdbc.queryForObject(sql, Integer.class, email);
        return count != null && count > 0;
    }
}
