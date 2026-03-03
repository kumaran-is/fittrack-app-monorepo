package com.fitness.api.progress;

import com.fitness.api.progress.dto.WeeklyStrengthPoint;
import com.fitness.api.progress.dto.WeeklyVolumePoint;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.r2dbc.core.DatabaseClient;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class ProgressService {

    private static final Logger log = LoggerFactory.getLogger(ProgressService.class);

    private final DatabaseClient databaseClient;

    public ProgressService(DatabaseClient databaseClient) {
        this.databaseClient = databaseClient;
    }

    public Flux<WeeklyStrengthPoint> getStrengthProgress(UUID exerciseId, UUID userId) {
        // H2 in PostgreSQL mode supports DATEADD and TRUNC; use PARSEDATETIME/FORMATDATETIME for week truncation
        // We use DATEADD to get start of week by truncating to Monday via arithmetic
        String sql = """
                SELECT DATEADD('day', -(EXTRACT(DOW FROM ss.logged_at) + 6) % 7, CAST(ss.logged_at AS DATE)) AS week_start,
                       MAX(ss.weight_kg) AS max_weight
                FROM session_sets ss
                JOIN workout_sessions ws ON ss.session_id = ws.id
                WHERE ss.exercise_id = :exerciseId
                  AND ws.user_id = :userId
                  AND ss.logged_at >= DATEADD('week', -12, CURRENT_TIMESTAMP)
                GROUP BY DATEADD('day', -(EXTRACT(DOW FROM ss.logged_at) + 6) % 7, CAST(ss.logged_at AS DATE))
                ORDER BY week_start
                """;

        return databaseClient.sql(sql)
                .bind("exerciseId", exerciseId)
                .bind("userId", userId)
                .map((row, meta) -> new WeeklyStrengthPoint(
                        row.get("week_start", LocalDateTime.class),
                        row.get("max_weight", BigDecimal.class)
                ))
                .all()
                .doOnError(err -> log.error("Error fetching strength progress: exerciseId={}, userId={}", exerciseId, userId, err));
    }

    public Flux<WeeklyVolumePoint> getVolumeProgress(UUID userId) {
        String sql = """
                SELECT DATEADD('day', -(EXTRACT(DOW FROM ss.logged_at) + 6) % 7, CAST(ss.logged_at AS DATE)) AS week_start,
                       SUM(CAST(ss.reps AS DECIMAL) * ss.weight_kg) AS total_volume
                FROM session_sets ss
                JOIN workout_sessions ws ON ss.session_id = ws.id
                WHERE ws.user_id = :userId
                  AND ss.logged_at >= DATEADD('week', -8, CURRENT_TIMESTAMP)
                GROUP BY DATEADD('day', -(EXTRACT(DOW FROM ss.logged_at) + 6) % 7, CAST(ss.logged_at AS DATE))
                ORDER BY week_start
                """;

        return databaseClient.sql(sql)
                .bind("userId", userId)
                .map((row, meta) -> new WeeklyVolumePoint(
                        row.get("week_start", LocalDateTime.class),
                        row.get("total_volume", BigDecimal.class)
                ))
                .all()
                .doOnError(err -> log.error("Error fetching volume progress: userId={}", userId, err));
    }
}
