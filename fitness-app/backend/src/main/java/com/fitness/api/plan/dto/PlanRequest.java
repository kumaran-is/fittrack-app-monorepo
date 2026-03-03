package com.fitness.api.plan.dto;

import jakarta.validation.constraints.NotBlank;

public record PlanRequest(
        @NotBlank String name,
        String description
) {}
