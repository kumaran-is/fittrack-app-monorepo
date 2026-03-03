package com.fitness.api.exercise.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record ExerciseRequest(
        @NotBlank String name,
        @NotBlank @Pattern(regexp = "CHEST|BACK|LEGS|SHOULDERS|ARMS|CORE|CARDIO",
                message = "Category must be one of: CHEST, BACK, LEGS, SHOULDERS, ARMS, CORE, CARDIO")
        String category,
        String muscleGroup,
        String description
) {}
