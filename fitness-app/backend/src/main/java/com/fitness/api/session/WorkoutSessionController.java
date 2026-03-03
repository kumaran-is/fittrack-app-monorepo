package com.fitness.api.session;

import com.fitness.api.session.dto.SessionRequest;
import com.fitness.api.session.dto.SessionResponse;
import com.fitness.api.session.dto.SetRequest;
import com.fitness.api.session.dto.SetResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/sessions")
public class WorkoutSessionController {

    private final WorkoutSessionService sessionService;

    public WorkoutSessionController(WorkoutSessionService sessionService) {
        this.sessionService = sessionService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<SessionResponse> startSession(@Valid @RequestBody SessionRequest request) {
        return currentUserId().flatMap(userId -> sessionService.startSession(request, userId));
    }

    @GetMapping
    public Flux<SessionResponse> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return currentUserId().flatMapMany(userId -> sessionService.findAll(userId, page, size));
    }

    @GetMapping("/{id}")
    public Mono<SessionResponse> getById(@PathVariable UUID id) {
        return currentUserId().flatMap(userId -> sessionService.findById(id, userId));
    }

    @PatchMapping("/{id}/complete")
    public Mono<SessionResponse> complete(@PathVariable UUID id) {
        return currentUserId().flatMap(userId -> sessionService.completeSession(id, userId));
    }

    @PostMapping("/{id}/sets")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<SetResponse> logSet(@PathVariable UUID id, @Valid @RequestBody SetRequest request) {
        return currentUserId().flatMap(userId -> sessionService.logSet(id, request, userId));
    }

    @DeleteMapping("/{id}/sets/{setId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> deleteSet(@PathVariable UUID id, @PathVariable UUID setId) {
        return currentUserId().flatMap(userId -> sessionService.deleteSet(id, setId, userId));
    }

    private Mono<UUID> currentUserId() {
        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> UUID.fromString(ctx.getAuthentication().getName()));
    }
}
