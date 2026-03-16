package com.finapp.repository;

import com.finapp.model.Category;
import com.finapp.model.MovementType;
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
public class CategoryRepository {

    private final JdbcTemplate jdbc;

    private final RowMapper<Category> categoryRowMapper = (rs, rowNum) -> Category.builder()
            .id(rs.getObject("id", UUID.class))
            .userId(rs.getObject("user_id", UUID.class))
            .name(rs.getString("name"))
            .type(MovementType.valueOf(rs.getString("type")))
            .build();

    public Category save(Category category) {
        String sql = """
                INSERT INTO categories (id, user_id, name, type)
                VALUES (uuid_generate_v4(), ?, ?, ?::movement_type)
                ON CONFLICT (user_id, name, type) DO UPDATE SET name = EXCLUDED.name
                RETURNING *
                """;
        return jdbc.queryForObject(sql, categoryRowMapper,
                category.getUserId(), category.getName(), category.getType().name());
    }

    public Optional<Category> findById(UUID id, UUID userId) {
        String sql = "SELECT * FROM categories WHERE id = ? AND user_id = ?";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, categoryRowMapper, id, userId));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public Optional<Category> findByNameAndType(String name, MovementType type, UUID userId) {
        String sql = "SELECT * FROM categories WHERE user_id = ? AND LOWER(name) = LOWER(?) AND type = ?::movement_type";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, categoryRowMapper, userId, name, type.name()));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public List<Category> findAllByUserId(UUID userId) {
        String sql = "SELECT * FROM categories WHERE user_id = ? ORDER BY type, name ASC";
        return jdbc.query(sql, categoryRowMapper, userId);
    }

    public List<Category> findAllByUserIdAndType(UUID userId, MovementType type) {
        String sql = "SELECT * FROM categories WHERE user_id = ? AND type = ?::movement_type ORDER BY name ASC";
        return jdbc.query(sql, categoryRowMapper, userId, type.name());
    }

    public Optional<Category> update(UUID id, UUID userId, String name) {
        String sql = "UPDATE categories SET name = ? WHERE id = ? AND user_id = ? RETURNING *";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, categoryRowMapper, name, id, userId));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public boolean delete(UUID id, UUID userId) {
        String sql = "DELETE FROM categories WHERE id = ? AND user_id = ?";
        return jdbc.update(sql, id, userId) > 0;
    }
}
