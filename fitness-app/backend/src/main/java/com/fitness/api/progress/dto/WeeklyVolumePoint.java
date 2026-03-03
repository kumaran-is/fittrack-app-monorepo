package com.fitness.api.progress.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record WeeklyVolumePoint(
        LocalDateTime weekStart,
        BigDecimal totalVolume
) {}
