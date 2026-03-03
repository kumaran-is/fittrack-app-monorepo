package com.fitness.api.session.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.UUID;

public record SetRequest(
        @NotNull UUID exerciseId,
        @Min(1) int setNumber,
        @Min(1) int reps,
        @NotNull @Min(0) BigDecimal weightKg,
        String notes
) {}
