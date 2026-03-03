package com.fitness.api.plan.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record PlanDayExerciseRequest(
        @NotNull UUID exerciseId,
        @Min(1) int sets,
        @Min(1) int reps,
        @Min(0) int restSeconds
) {}
