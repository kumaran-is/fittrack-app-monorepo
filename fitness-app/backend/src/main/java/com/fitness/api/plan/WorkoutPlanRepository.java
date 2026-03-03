package com.fitness.api.plan;

import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

public interface WorkoutPlanRepository extends ReactiveCrudRepository<WorkoutPlan, UUID> {

    Flux<WorkoutPlan> findByUserIdOrderByCreatedAtDesc(UUID userId);

    Mono<WorkoutPlan> findByIdAndUserId(UUID id, UUID userId);
}
