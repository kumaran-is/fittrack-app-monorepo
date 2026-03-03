package com.fitness.api.session;

import com.fitness.api.exception.ResourceNotFoundException;
import com.fitness.api.exception.ValidationException;
import com.fitness.api.exercise.Exercise;
import com.fitness.api.exercise.ExerciseRepository;
import com.fitness.api.session.dto.SessionRequest;
import com.fitness.api.session.dto.SessionResponse;
import com.fitness.api.session.dto.SetRequest;
import com.fitness.api.session.dto.SetResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class WorkoutSessionService {

    private static final Logger log = LoggerFactory.getLogger(WorkoutSessionService.class);

    private final WorkoutSessionRepository sessionRepository;
    private final SessionSetRepository setRepository;
    private final ExerciseRepository exerciseRepository;

    public WorkoutSessionService(
            WorkoutSessionRepository sessionRepository,
            SessionSetRepository setRepository,
            ExerciseRepository exerciseRepository) {
        this.sessionRepository = sessionRepository;
        this.setRepository = setRepository;
        this.exerciseRepository = exerciseRepository;
    }

    @Transactional
    public Mono<SessionResponse> startSession(SessionRequest request, UUID userId) {
        WorkoutSession session = new WorkoutSession();
        session.setUserId(userId);
        session.setPlanId(request.planId());
        session.setName(request.name());
        session.setStartedAt(LocalDateTime.now());

        return sessionRepository.save(session)
                .map(saved -> toSessionResponse(saved, List.of()))
                .doOnSuccess(s -> log.info("Session started: id={}, userId={}", s.id(), userId));
    }

    public Flux<SessionResponse> findAll(UUID userId, int page, int size) {
        return sessionRepository.findByUserIdOrderByStartedAtDesc(userId, PageRequest.of(page, size))
                .flatMap(session -> setRepository.findBySessionIdOrderBySetNumber(session.getId())
                        .flatMap(set -> exerciseRepository.findById(set.getExerciseId())
                                .map(ex -> toSetResponse(set, ex)))
                        .collectList()
                        .map(sets -> toSessionResponse(session, sets)));
    }

    public Mono<SessionResponse> findById(UUID id, UUID userId) {
        return sessionRepository.findByIdAndUserId(id, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutSession", id)))
                .flatMap(session -> setRepository.findBySessionIdOrderBySetNumber(session.getId())
                        .flatMap(set -> exerciseRepository.findById(set.getExerciseId())
                                .map(ex -> toSetResponse(set, ex)))
                        .collectList()
                        .map(sets -> toSessionResponse(session, sets)));
    }

    @Transactional
    public Mono<SessionResponse> completeSession(UUID id, UUID userId) {
        return sessionRepository.findByIdAndUserId(id, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutSession", id)))
                .flatMap(session -> {
                    if (session.getCompletedAt() != null) {
                        return Mono.error(new ValidationException("Session is already completed"));
                    }
                    session.setCompletedAt(LocalDateTime.now());
                    return sessionRepository.save(session);
                })
                .flatMap(session -> setRepository.findBySessionIdOrderBySetNumber(session.getId())
                        .flatMap(set -> exerciseRepository.findById(set.getExerciseId())
                                .map(ex -> toSetResponse(set, ex)))
                        .collectList()
                        .map(sets -> toSessionResponse(session, sets)))
                .doOnSuccess(s -> log.info("Session completed: id={}, userId={}", id, userId));
    }

    @Transactional
    public Mono<SetResponse> logSet(UUID sessionId, SetRequest request, UUID userId) {
        return sessionRepository.findByIdAndUserId(sessionId, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutSession", sessionId)))
                .flatMap(session -> {
                    if (session.getCompletedAt() != null) {
                        return Mono.error(new ValidationException("Cannot log sets for a completed session"));
                    }
                    return exerciseRepository.findById(request.exerciseId())
                            .switchIfEmpty(Mono.error(new ResourceNotFoundException("Exercise", request.exerciseId())))
                            .flatMap(exercise -> {
                                SessionSet set = new SessionSet();
                                set.setSessionId(sessionId);
                                set.setExerciseId(request.exerciseId());
                                set.setSetNumber(request.setNumber());
                                set.setReps(request.reps());
                                set.setWeightKg(request.weightKg());
                                set.setNotes(request.notes());
                                set.setLoggedAt(LocalDateTime.now());
                                return setRepository.save(set)
                                        .map(saved -> toSetResponse(saved, exercise));
                            });
                })
                .doOnSuccess(s -> log.info("Set logged: setId={}, sessionId={}", s.id(), sessionId));
    }

    @Transactional
    public Mono<Void> deleteSet(UUID sessionId, UUID setId, UUID userId) {
        return sessionRepository.findByIdAndUserId(sessionId, userId)
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("WorkoutSession", sessionId)))
                .flatMap(session -> setRepository.findByIdAndSessionId(setId, sessionId))
                .switchIfEmpty(Mono.error(new ResourceNotFoundException("SessionSet", setId)))
                .flatMap(set -> setRepository.delete(set))
                .doOnSuccess(v -> log.info("Set deleted: setId={}, sessionId={}", setId, sessionId));
    }

    private SessionResponse toSessionResponse(WorkoutSession session, List<SetResponse> sets) {
        return new SessionResponse(
                session.getId(),
                session.getName(),
                session.getPlanId(),
                session.getStartedAt(),
                session.getCompletedAt(),
                session.getCompletedAt() != null,
                sets
        );
    }

    private SetResponse toSetResponse(SessionSet set, Exercise exercise) {
        return new SetResponse(
                set.getId(),
                exercise.getId(),
                exercise.getName(),
                set.getSetNumber(),
                set.getReps(),
                set.getWeightKg(),
                set.getNotes(),
                set.getLoggedAt()
        );
    }
}
