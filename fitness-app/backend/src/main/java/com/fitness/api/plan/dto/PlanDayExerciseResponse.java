package com.fitness.api.plan.dto;

import java.util.UUID;

public record PlanDayExerciseResponse(
        UUID id,
        UUID exerciseId,
        String exerciseName,
        String category,
        int sets,
        int reps,
        int restSeconds
) {}
