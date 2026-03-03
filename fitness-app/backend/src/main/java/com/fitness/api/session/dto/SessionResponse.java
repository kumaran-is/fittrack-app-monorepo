package com.fitness.api.session.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record SessionResponse(
        UUID id,
        String name,
        UUID planId,
        LocalDateTime startedAt,
        LocalDateTime completedAt,
        boolean completed,
        List<SetResponse> sets
) {}
