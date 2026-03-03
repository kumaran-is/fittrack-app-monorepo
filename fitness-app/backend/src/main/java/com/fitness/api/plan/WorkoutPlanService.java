package com.fitness.api.plan;

import com.fitness.api.exception.ResourceNotFoundException;
import com.fitness.api.exception.UnauthorizedException;
import com.fitness.api.exercise.Exercise;
import com.fitness.api.exercise.ExerciseRepository;
import com.fitness.api.plan.dto.DayRequest;
import com.fitness.api.plan.dto.DayResponse;
import com.fitness.api.plan.dto.PlanDayExerciseRequest;
import com.fitness.api.plan.dto.PlanDayExerciseResponse;
import com.fitness.api.plan.dto.PlanRequest;
import com.fitness.api.plan.dto.PlanResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.UUID;

@Service
public class WorkoutPlanService {

    private static final Logger log = LoggerFactory.getLogger(WorkoutPlanService.class);

    private final WorkoutPlanRepository planRepository;
    private final PlanDayRepository dayRepository;
    private final PlanDayExerciseRepository dayExerciseRepository;
    private final ExerciseRepository exerciseRepository;

    public WorkoutPlanService(
            WorkoutPlanRepository planRepository,
            PlanDayRepository dayRepository,
            PlanDayExerciseRepository dayExerciseRepository,
            ExerciseRepository exerciseRepository) {
        this.planRepository = planRepository;
        this.dayRepository = dayRepository;
        this.dayExerciseRepository = dayExerciseRepository;
        this.exerciseRepository = exerciseRepository;
    }

    public Flux<PlanResponse> findAll(UUID userId) {
        return planRepository.findByUserIdOrderByCreatedAtDesc(userId)
                .flatMap(plan -> buildPlanResponse(plan, false));
    }

    public Mono<PlanResponse> findById(UUID id, UUID userId) {
        return planRepository.findByIdAndUserId(id, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutPlan", id)))
                .flatMap(plan -> buildPlanResponse(plan, true));
    }

    @Transactional
    public Mono<PlanResponse> create(PlanRequest request, UUID userId) {
        WorkoutPlan plan = new WorkoutPlan();
        plan.setUserId(userId);
        plan.setName(request.name());
        plan.setDescription(request.description());

        return planRepository.save(plan)
                .flatMap(saved -> buildPlanResponse(saved, false))
                .doOnSuccess(p -> log.info("Plan created: id={}, userId={}", p.id(), userId));
    }

    @Transactional
    public Mono<PlanResponse> update(UUID id, PlanRequest request, UUID userId) {
        return planRepository.findByIdAndUserId(id, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutPlan", id)))
                .flatMap(plan -> {
                    plan.setName(request.name());
                    plan.setDescription(request.description());
                    return planRepository.save(plan);
                })
                .flatMap(saved -> buildPlanResponse(saved, true))
                .doOnSuccess(p -> log.info("Plan updated: id={}, userId={}", id, userId));
    }

    @Transactional
    public Mono<Void> delete(UUID id, UUID userId) {
        return planRepository.findByIdAndUserId(id, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutPlan", id)))
                .flatMap(plan -> planRepository.delete(plan))
                .doOnSuccess(v -> log.info("Plan deleted: id={}, userId={}", id, userId));
    }

    @Transactional
    public Mono<DayResponse> addDay(UUID planId, DayRequest request, UUID userId) {
        return planRepository.findByIdAndUserId(planId, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutPlan", planId)))
                .flatMap(plan -> {
                    PlanDay day = new PlanDay();
                    day.setPlanId(planId);
                    day.setName(request.name());
                    day.setOrderIndex(request.orderIndex());
                    return dayRepository.save(day);
                })
                .flatMap(day -> buildDayResponse(day, true))
                .doOnSuccess(d -> log.info("Day added: dayId={}, planId={}", d.id(), planId));
    }

    @Transactional
    public Mono<Void> removeDay(UUID planId, UUID dayId, UUID userId) {
        return planRepository.findByIdAndUserId(planId, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutPlan", planId)))
                .flatMap(plan -> dayRepository.findByIdAndPlanId(dayId, planId))
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("PlanDay", dayId)))
                .flatMap(day -> dayRepository.delete(day))
                .doOnSuccess(v -> log.info("Day removed: dayId={}, planId={}", dayId, planId));
    }

    @Transactional
    public Mono<PlanDayExerciseResponse> addExerciseToDay(
            UUID planId, UUID dayId, PlanDayExerciseRequest request, UUID userId) {
        return planRepository.findByIdAndUserId(planId, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutPlan", planId)))
                .flatMap(plan -> dayRepository.findByIdAndPlanId(dayId, planId))
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("PlanDay", dayId)))
                .flatMap(day -> exerciseRepository.findById(request.exerciseId())
                        .switchIfEmpty(Mono.error(new ResourceNotFoundException("Exercise", request.exerciseId())))
                        .flatMap(exercise -> {
                            PlanDayExercise pde = new PlanDayExercise();
                            pde.setDayId(dayId);
                            pde.setExerciseId(request.exerciseId());
                            pde.setSets(request.sets());
                            pde.setReps(request.reps());
                            pde.setRestSeconds(request.restSeconds());
                            return dayExerciseRepository.save(pde)
                                    .map(saved -> toPlanDayExerciseResponse(saved, exercise));
                        }))
                .doOnSuccess(r -> log.info("Exercise added to day: exerciseId={}, dayId={}", request.exerciseId(), dayId));
    }

    @Transactional
    public Mono<Void> removeExerciseFromDay(UUID planId, UUID dayId, UUID exerciseEntryId, UUID userId) {
        return planRepository.findByIdAndUserId(planId, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutPlan", planId)))
                .flatMap(plan -> dayRepository.findByIdAndPlanId(dayId, planId))
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("PlanDay", dayId)))
                .flatMap(day -> dayExerciseRepository.findByIdAndDayId(exerciseEntryId, dayId))
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("PlanDayExercise", exerciseEntryId)))
                .flatMap(dayExerciseRepository::delete)
                .doOnSuccess(v -> log.info("Exercise removed from day: entryId={}, dayId={}", exerciseEntryId, dayId));
    }

    private Mono<PlanResponse> buildPlanResponse(WorkoutPlan plan, boolean includeDays) {
        if (!includeDays) {
            return Mono.just(new PlanResponse(
                    plan.getId(), plan.getName(), plan.getDescription(),
                    List.of(), plan.getCreatedAt(), plan.getUpdatedAt()));
        }
        return dayRepository.findByPlanIdOrderByOrderIndex(plan.getId())
                .flatMap(day -> buildDayResponse(day, true))
                .collectList()
                .map(days -> new PlanResponse(
                        plan.getId(), plan.getName(), plan.getDescription(),
                        days, plan.getCreatedAt(), plan.getUpdatedAt()));
    }

    private Mono<DayResponse> buildDayResponse(PlanDay day, boolean includeExercises) {
        if (!includeExercises) {
            return Mono.just(new DayResponse(day.getId(), day.getName(), day.getOrderIndex(), List.of()));
        }
        return dayExerciseRepository.findByDayId(day.getId())
                .flatMap(pde -> exerciseRepository.findById(pde.getExerciseId())
                        .map(exercise -> toPlanDayExerciseResponse(pde, exercise)))
                .collectList()
                .map(exercises -> new DayResponse(day.getId(), day.getName(), day.getOrderIndex(), exercises));
    }

    private PlanDayExerciseResponse toPlanDayExerciseResponse(PlanDayExercise pde, Exercise exercise) {
        return new PlanDayExerciseResponse(
                pde.getId(),
                exercise.getId(),
                exercise.getName(),
                exercise.getCategory(),
                pde.getSets(),
                pde.getReps(),
                pde.getRestSeconds()
        );
    }
}
