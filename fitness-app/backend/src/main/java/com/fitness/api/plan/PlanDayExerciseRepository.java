package com.fitness.api.plan;

import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

public interface PlanDayExerciseRepository extends ReactiveCrudRepository<PlanDayExercise, UUID> {

    Flux<PlanDayExercise> findByDayId(UUID dayId);

    Mono<PlanDayExercise> findByIdAndDayId(UUID id, UUID dayId);

    Mono<Void> deleteByDayId(UUID dayId);
}
