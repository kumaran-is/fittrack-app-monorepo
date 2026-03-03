package com.fitness.api.plan.dto;

import jakarta.validation.constraints.NotBlank;

public record DayRequest(
        @NotBlank String name,
        int orderIndex
) {}
