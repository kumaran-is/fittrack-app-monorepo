package com.fitness.api.plan.dto;

import java.util.List;
import java.util.UUID;

public record DayResponse(
        UUID id,
        String name,
        int orderIndex,
        List<PlanDayExerciseResponse> exercises
) {}
