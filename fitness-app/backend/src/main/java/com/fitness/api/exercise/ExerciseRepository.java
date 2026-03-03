package com.fitness.api.exercise;

import org.springframework.data.r2dbc.repository.Query;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

public interface ExerciseRepository extends ReactiveCrudRepository<Exercise, UUID> {

    @Query("SELECT * FROM exercises WHERE (user_id IS NULL OR user_id = :userId) ORDER BY name")
    Flux<Exercise> findAllVisibleToUser(UUID userId);

    @Query("SELECT * FROM exercises WHERE (user_id IS NULL OR user_id = :userId) AND category = :category ORDER BY name")
    Flux<Exercise> findByCategory(UUID userId, String category);

    @Query("SELECT * FROM exercises WHERE (user_id IS NULL OR user_id = :userId) AND LOWER(name) LIKE LOWER(CONCAT('%', :query, '%')) ORDER BY name")
    Flux<Exercise> findByNameContaining(UUID userId, String query);

    @Query("SELECT * FROM exercises WHERE (user_id IS NULL OR user_id = :userId) AND category = :category AND LOWER(name) LIKE LOWER(CONCAT('%', :query, '%')) ORDER BY name")
    Flux<Exercise> findByCategoryAndNameContaining(UUID userId, String category, String query);

    Mono<Long> countByUserIdAndId(UUID userId, UUID id);
}
