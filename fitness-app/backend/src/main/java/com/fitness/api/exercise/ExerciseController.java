package com.fitness.api.exercise;

import com.fitness.api.exercise.dto.ExerciseRequest;
import com.fitness.api.exercise.dto.ExerciseResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
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
@RequestMapping("/api/v1/exercises")
public class ExerciseController {

    private final ExerciseService exerciseService;

    public ExerciseController(ExerciseService exerciseService) {
        this.exerciseService = exerciseService;
    }

    @GetMapping
    public Flux<ExerciseResponse> getAll(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String q) {
        return currentUserId()
                .flatMapMany(userId -> exerciseService.findAll(userId, category, q));
    }

    @GetMapping("/{id}")
    public Mono<ExerciseResponse> getById(@PathVariable UUID id) {
        return currentUserId()
                .flatMap(userId -> exerciseService.findById(id, userId));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<ExerciseResponse> create(@Valid @RequestBody ExerciseRequest request) {
        return currentUserId()
                .flatMap(userId -> exerciseService.create(request, userId));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable UUID id) {
        return currentUserId()
                .flatMap(userId -> exerciseService.delete(id, userId));
    }

    private Mono<UUID> currentUserId() {
        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> UUID.fromString(ctx.getAuthentication().getName()));
    }
}
