package com.fitness.api.session;

import org.springframework.data.repository.reactive.ReactiveCrudRepository;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

public interface SessionSetRepository extends ReactiveCrudRepository<SessionSet, UUID> {

    Flux<SessionSet> findBySessionIdOrderBySetNumber(UUID sessionId);

    Mono<SessionSet> findByIdAndSessionId(UUID id, UUID sessionId);
}
