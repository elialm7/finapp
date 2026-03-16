package com.finapp.repository;

import com.finapp.model.Account;
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
public class AccountRepository {

    private final JdbcTemplate jdbc;

    private final RowMapper<Account> accountRowMapper = (rs, rowNum) -> Account.builder()
            .id(rs.getObject("id", UUID.class))
            .userId(rs.getObject("user_id", UUID.class))
            .name(rs.getString("name"))
            .currentBalance(rs.getBigDecimal("current_balance"))
            .createdAt(rs.getObject("created_at", java.time.OffsetDateTime.class))
            .build();

    public Account save(Account account) {
        String sql = """
                INSERT INTO accounts (id, user_id, name, current_balance)
                VALUES (uuid_generate_v4(), ?, ?, ?)
                RETURNING *
                """;
        return jdbc.queryForObject(sql, accountRowMapper,
                account.getUserId(), account.getName(), account.getCurrentBalance());
    }

    public Optional<Account> findById(UUID id, UUID userId) {
        String sql = "SELECT * FROM accounts WHERE id = ? AND user_id = ?";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, accountRowMapper, id, userId));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public List<Account> findAllByUserId(UUID userId) {
        String sql = "SELECT * FROM accounts WHERE user_id = ? ORDER BY name ASC";
        return jdbc.query(sql, accountRowMapper, userId);
    }

    public Optional<Account> update(UUID id, UUID userId, String name) {
        String sql = """
                UPDATE accounts SET name = ?
                WHERE id = ? AND user_id = ?
                RETURNING *
                """;
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, accountRowMapper, name, id, userId));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public boolean delete(UUID id, UUID userId) {
        String sql = "DELETE FROM accounts WHERE id = ? AND user_id = ?";
        return jdbc.update(sql, id, userId) > 0;
    }

    public void updateBalance(UUID accountId, java.math.BigDecimal delta) {
        String sql = "UPDATE accounts SET current_balance = current_balance + ? WHERE id = ?";
        jdbc.update(sql, delta, accountId);
    }
}
