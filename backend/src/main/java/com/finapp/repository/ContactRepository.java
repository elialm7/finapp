package com.finapp.repository;

import com.finapp.model.Contact;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class ContactRepository {

    private final JdbcTemplate jdbc;

    private final RowMapper<Contact> contactRowMapper = (rs, rowNum) -> Contact.builder()
            .id(rs.getObject("id", UUID.class))
            .userId(rs.getObject("user_id", UUID.class))
            .name(rs.getString("name"))
            .description(rs.getString("description"))
            .createdAt(rs.getObject("created_at", java.time.OffsetDateTime.class))
            .build();

    public Contact save(Contact contact) {
        String sql = """
                INSERT INTO contacts (id, user_id, name, description)
                VALUES (uuid_generate_v4(), ?, ?, ?)
                RETURNING *
                """;
        return jdbc.queryForObject(sql, contactRowMapper,
                contact.getUserId(), contact.getName(), contact.getDescription());
    }

    public Optional<Contact> findById(UUID id, UUID userId) {
        String sql = "SELECT * FROM contacts WHERE id = ? AND user_id = ?";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, contactRowMapper, id, userId));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public List<Contact> findAllByUserId(UUID userId) {
        String sql = "SELECT * FROM contacts WHERE user_id = ? ORDER BY name ASC";
        return jdbc.query(sql, contactRowMapper, userId);
    }

    public List<Contact> searchByName(UUID userId, String name) {
        String sql = "SELECT * FROM contacts WHERE user_id = ? AND LOWER(name) LIKE LOWER(?) ORDER BY name ASC";
        return jdbc.query(sql, contactRowMapper, userId, "%" + name + "%");
    }

    public Optional<Contact> update(UUID id, UUID userId, String name, String description) {
        String sql = "UPDATE contacts SET name = ?, description = ? WHERE id = ? AND user_id = ? RETURNING *";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, contactRowMapper, name, description, id, userId));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public boolean delete(UUID id, UUID userId) {
        String sql = "DELETE FROM contacts WHERE id = ? AND user_id = ?";
        return jdbc.update(sql, id, userId) > 0;
    }
}
