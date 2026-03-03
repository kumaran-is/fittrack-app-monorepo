package com.fitness.api.exercise;

import com.fitness.api.exception.ResourceNotFoundException;
import com.fitness.api.exception.UnauthorizedException;
import com.fitness.api.exercise.dto.ExerciseRequest;
import com.fitness.api.exercise.dto.ExerciseResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@Service
public class ExerciseService {

    private static final Logger log = LoggerFactory.getLogger(ExerciseService.class);

    private final ExerciseRepository exerciseRepository;

    public ExerciseService(ExerciseRepository exerciseRepository) {
        this.exerciseRepository = exerciseRepository;
    }

    public Flux<ExerciseResponse> findAll(UUID userId, String category, String query) {
        Flux<Exercise> exercises;

        boolean hasCategory = category != null && !category.isBlank();
        boolean hasQuery = query != null && !query.isBlank();

        if (hasCategory && hasQuery) {
            exercises = exerciseRepository.findByCategoryAndNameContaining(userId, category.toUpperCase(), query);
        } else if (hasCategory) {
            exercises = exerciseRepository.findByCategory(userId, category.toUpperCase());
        } else if (hasQuery) {
            exercises = exerciseRepository.findByNameContaining(userId, query);
        } else {
            exercises = exerciseRepository.findAllVisibleToUser(userId);
        }

        return exercises.map(e -> toResponse(e, userId));
    }

    public Mono<ExerciseResponse> findById(UUID id, UUID userId) {
        return exerciseRepository.findById(id)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("Exercise", id)))
                .flatMap(exercise -> {
                    // Hide another user's custom exercises — return 404 to avoid revealing existence
                    if (exercise.getUserId() != null && !exercise.getUserId().equals(userId)) {
                        return Mono.error(new ResourceNotFoundException("Exercise", id));
                    }
                    return Mono.just(toResponse(exercise, userId));
                });
    }

    public Mono<ExerciseResponse> create(ExerciseRequest request, UUID userId) {
        Exercise exercise = new Exercise();
        exercise.setName(request.name());
        exercise.setCategory(request.category().toUpperCase());
        exercise.setMuscleGroup(request.muscleGroup());
        exercise.setDescription(request.description());
        exercise.setUserId(userId);

        return exerciseRepository.save(exercise)
                .map(e -> toResponse(e, userId))
                .doOnSuccess(e -> log.info("Exercise created: id={}, userId={}", e.id(), userId));
    }

    public Mono<Void> delete(UUID id, UUID userId) {
        return exerciseRepository.findById(id)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("Exercise", id)))
                .flatMap(exercise -> {
                    if (exercise.getUserId() == null || !exercise.getUserId().equals(userId)) {
                        return Mono.error(new UnauthorizedException("Cannot delete a system or another user's exercise"));
                    }
                    return exerciseRepository.delete(exercise)
                            .doOnSuccess(v -> log.info("Exercise deleted: id={}, userId={}", id, userId));
                });
    }

    private ExerciseResponse toResponse(Exercise exercise, UUID requestingUserId) {
        return new ExerciseResponse(
                exercise.getId(),
                exercise.getName(),
                exercise.getCategory(),
                exercise.getMuscleGroup(),
                exercise.getDescription(),
                exercise.getUserId() != null
        );
    }
}
