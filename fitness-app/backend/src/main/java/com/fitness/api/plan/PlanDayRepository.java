package com.fitness.api.plan;

import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

public interface PlanDayRepository extends ReactiveCrudRepository<PlanDay, UUID> {

    Flux<PlanDay> findByPlanIdOrderByOrderIndex(UUID planId);

    Mono<PlanDay> findByIdAndPlanId(UUID id, UUID planId);

    Mono<Void> deleteByPlanId(UUID planId);
}
