package com.fitness.api.exercise.dto;

import java.util.UUID;

public record ExerciseResponse(
        UUID id,
        String name,
        String category,
        String muscleGroup,
        String description,
        boolean isCustom
) {}
