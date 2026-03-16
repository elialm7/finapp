package com.finapp.repository;

import com.finapp.model.MovementType;
import com.finapp.model.Transaction;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@Repository
@RequiredArgsConstructor
public class TransactionRepository {

    private final JdbcTemplate jdbc;

    private final RowMapper<Transaction> txRowMapper = (rs, rowNum) -> Transaction.builder()
            .id(rs.getObject("id", UUID.class))
            .userId(rs.getObject("user_id", UUID.class))
            .accountId(rs.getObject("account_id", UUID.class))
            .destinationAccountId(rs.getObject("destination_account_id", UUID.class))
            .contactId(rs.getObject("contact_id", UUID.class))
            .categoryId(rs.getObject("category_id", UUID.class))
            .amount(rs.getBigDecimal("amount"))
            .type(MovementType.valueOf(rs.getString("type")))
            .description(rs.getString("description"))
            .transactionDate(rs.getObject("transaction_date", OffsetDateTime.class))
            .createdAt(rs.getObject("created_at", OffsetDateTime.class))
            .build();

    public Transaction save(Transaction tx) {
        String sql = """
                INSERT INTO transactions
                    (id, user_id, account_id, destination_account_id, contact_id, category_id,
                     amount, type, description, transaction_date)
                VALUES
                    (uuid_generate_v4(), ?, ?, ?, ?, ?, ?, ?::movement_type, ?, ?)
                RETURNING *
                """;
        return jdbc.queryForObject(sql, txRowMapper,
                tx.getUserId(),
                tx.getAccountId(),
                tx.getDestinationAccountId(),
                tx.getContactId(),
                tx.getCategoryId(),
                tx.getAmount(),
                tx.getType().name(),
                tx.getDescription(),
                tx.getTransactionDate());
    }

    public Optional<Transaction> findById(UUID id, UUID userId) {
        String sql = "SELECT * FROM transactions WHERE id = ? AND user_id = ?";
        try {
            return Optional.ofNullable(jdbc.queryForObject(sql, txRowMapper, id, userId));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    public List<Transaction> findByUserAndDateRange(UUID userId, OffsetDateTime from, OffsetDateTime to, int limit, int offset) {
        String sql = """
                SELECT * FROM transactions
                WHERE user_id = ?
                  AND transaction_date BETWEEN ? AND ?
                ORDER BY transaction_date DESC
                LIMIT ? OFFSET ?
                """;
        return jdbc.query(sql, txRowMapper, userId, from, to, limit, offset);
    }

    public int countByUserAndDateRange(UUID userId, OffsetDateTime from, OffsetDateTime to) {
        String sql = """
                SELECT COUNT(*) FROM transactions
                WHERE user_id = ? AND transaction_date BETWEEN ? AND ?
                """;
        Integer count = jdbc.queryForObject(sql, Integer.class, userId, from, to);
        return count != null ? count : 0;
    }

    public boolean delete(UUID id, UUID userId) {
        String sql = "DELETE FROM transactions WHERE id = ? AND user_id = ?";
        return jdbc.update(sql, id, userId) > 0;
    }

    // Dashboard summary query
    public Map<String, BigDecimal> getSummary(UUID userId, OffsetDateTime from, OffsetDateTime to) {
        String sql = """
                SELECT
                    COALESCE(SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END), 0)    AS total_income,
                    COALESCE(SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END), 0)   AS total_expenses,
                    COALESCE(SUM(CASE WHEN type = 'TRANSFER' THEN amount ELSE 0 END), 0)  AS total_transferred
                FROM transactions
                WHERE user_id = ? AND transaction_date BETWEEN ? AND ?
                """;
        return jdbc.queryForObject(sql, (rs, rn) -> Map.of(
                "totalIncome", rs.getBigDecimal("total_income"),
                "totalExpenses", rs.getBigDecimal("total_expenses"),
                "totalTransferred", rs.getBigDecimal("total_transferred")
        ), userId, from, to);
    }

    public List<Map<String, Object>> getTopCategories(UUID userId, OffsetDateTime from, OffsetDateTime to, MovementType type, int limit) {
        String sql = """
                SELECT c.name AS category_name,
                       COALESCE(SUM(t.amount), 0) AS total,
                       COUNT(t.id) AS count
                FROM transactions t
                JOIN categories c ON t.category_id = c.id
                WHERE t.user_id = ?
                  AND t.type = ?::movement_type
                  AND t.transaction_date BETWEEN ? AND ?
                GROUP BY c.name
                ORDER BY total DESC
                LIMIT ?
                """;
        return jdbc.queryForList(sql, userId, type.name(), from, to, limit);
    }
}
