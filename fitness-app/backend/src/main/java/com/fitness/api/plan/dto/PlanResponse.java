package com.fitness.api.plan.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record PlanResponse(
        UUID id,
        String name,
        String description,
        List<DayResponse> days,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {}
