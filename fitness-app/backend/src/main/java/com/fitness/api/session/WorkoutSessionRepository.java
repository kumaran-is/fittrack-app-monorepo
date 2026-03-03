package com.fitness.api.session;

import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

public interface WorkoutSessionRepository extends ReactiveCrudRepository<WorkoutSession, UUID> {

    Flux<WorkoutSession> findByUserIdOrderByStartedAtDesc(UUID userId, Pageable pageable);

    Mono<WorkoutSession> findByIdAndUserId(UUID id, UUID userId);
}
