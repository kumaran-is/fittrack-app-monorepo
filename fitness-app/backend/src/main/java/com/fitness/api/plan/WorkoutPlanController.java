package com.fitness.api.plan;

import com.fitness.api.plan.dto.DayRequest;
import com.fitness.api.plan.dto.DayResponse;
import com.fitness.api.plan.dto.PlanDayExerciseRequest;
import com.fitness.api.plan.dto.PlanDayExerciseResponse;
import com.fitness.api.plan.dto.PlanRequest;
import com.fitness.api.plan.dto.PlanResponse;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/plans")
public class WorkoutPlanController {

    private final WorkoutPlanService planService;

    public WorkoutPlanController(WorkoutPlanService planService) {
        this.planService = planService;
    }

    @GetMapping
    public Flux<PlanResponse> getAll() {
        return currentUserId().flatMapMany(planService::findAll);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<PlanResponse> create(@Valid @RequestBody PlanRequest request) {
        return currentUserId().flatMap(userId -> planService.create(request, userId));
    }

    @GetMapping("/{id}")
    public Mono<PlanResponse> getById(@PathVariable UUID id) {
        return currentUserId().flatMap(userId -> planService.findById(id, userId));
    }

    @PutMapping("/{id}")
    public Mono<PlanResponse> update(@PathVariable UUID id, @Valid @RequestBody PlanRequest request) {
        return currentUserId().flatMap(userId -> planService.update(id, request, userId));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> delete(@PathVariable UUID id) {
        return currentUserId().flatMap(userId -> planService.delete(id, userId));
    }

    @PostMapping("/{id}/days")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<DayResponse> addDay(@PathVariable UUID id, @Valid @RequestBody DayRequest request) {
        return currentUserId().flatMap(userId -> planService.addDay(id, request, userId));
    }

    @DeleteMapping("/{id}/days/{dayId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> removeDay(@PathVariable UUID id, @PathVariable UUID dayId) {
        return currentUserId().flatMap(userId -> planService.removeDay(id, dayId, userId));
    }

    @PostMapping("/{id}/days/{dayId}/exercises")
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<PlanDayExerciseResponse> addExerciseToDay(
            @PathVariable UUID id,
            @PathVariable UUID dayId,
            @Valid @RequestBody PlanDayExerciseRequest request) {
        return currentUserId().flatMap(userId -> planService.addExerciseToDay(id, dayId, request, userId));
    }

    @DeleteMapping("/{id}/days/{dayId}/exercises/{exId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public Mono<Void> removeExerciseFromDay(
            @PathVariable UUID id,
            @PathVariable UUID dayId,
            @PathVariable UUID exId) {
        return currentUserId().flatMap(userId -> planService.removeExerciseFromDay(id, dayId, exId, userId));
    }

    private Mono<UUID> currentUserId() {
        return ReactiveSecurityContextHolder.getContext()
                .map(ctx -> UUID.fromString(ctx.getAuthentication().getName()));
    }
}
