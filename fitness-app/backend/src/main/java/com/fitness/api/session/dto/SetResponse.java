package com.fitness.api.session.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record SetResponse(
        UUID id,
        UUID exerciseId,
        String exerciseName,
        int setNumber,
        int reps,
        BigDecimal weightKg,
        String notes,
        LocalDateTime loggedAt
) {}
